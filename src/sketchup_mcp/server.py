from mcp.server.fastmcp import FastMCP, Context
import socket
import json
import logging
from dataclasses import dataclass
from contextlib import asynccontextmanager
from typing import AsyncIterator, Dict, Any

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger("SketchupMCPServer")
__version__ = "0.1.17"

@dataclass
class SketchupConnection:
    host: str
    port: int
    sock: socket.socket = None

    def connect(self) -> bool:
        if self.sock:
            self.disconnect()
        try:
            self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.sock.connect((self.host, self.port))
            return True
        except Exception as e:
            logger.error(f"Failed to connect to Sketchup: {str(e)}")
            self.sock = None
            return False

    def disconnect(self):
        if self.sock:
            try:
                self.sock.close()
            except Exception:
                pass
            finally:
                self.sock = None

    def receive_full_response(self, sock, buffer_size=8192):
        chunks = []
        sock.settimeout(15.0)
        while True:
            try:
                chunk = sock.recv(buffer_size)
                if not chunk:
                    break
                chunks.append(chunk)
                data = b''.join(chunks)
                json.loads(data.decode('utf-8'))
                return data
            except json.JSONDecodeError:
                continue
            except socket.timeout:
                break
        if chunks:
            return b''.join(chunks)
        raise Exception("No data received from Sketchup")

    def send_command(self, method: str, params: Dict[str, Any] = None, request_id: Any = None) -> Dict[str, Any]:
        if not self.connect():
            raise ConnectionError("Not connected to Sketchup")
        if method == "tools/call" and params and "name" in params and "arguments" in params:
            request = {"jsonrpc": "2.0", "method": method, "params": params, "id": request_id}
        else:
            request = {"jsonrpc": "2.0", "method": "tools/call", "params": {"name": method, "arguments": params or {}}, "id": request_id}
        try:
            self.sock.sendall(json.dumps(request).encode('utf-8') + b'\n')
            response_data = self.receive_full_response(self.sock)
            self.disconnect()
            response = json.loads(response_data.decode('utf-8'))
            if isinstance(response, dict) and "error" in response:
                raise Exception(response["error"].get("message", "Unknown error from Sketchup"))
            return response.get("result", {}) if isinstance(response, dict) else response
        except Exception as e:
            self.disconnect()
            raise Exception(f"Communication error with Sketchup: {str(e)}")

_sketchup_connection = None

def get_sketchup_connection():
    global _sketchup_connection
    if _sketchup_connection is None:
        _sketchup_connection = SketchupConnection(host="127.0.0.1", port=9876)
    return _sketchup_connection

@asynccontextmanager
async def server_lifespan(server: FastMCP) -> AsyncIterator[Dict[str, Any]]:
    yield {}
    global _sketchup_connection
    if _sketchup_connection:
        _sketchup_connection.disconnect()
        _sketchup_connection = None

mcp = FastMCP("SketchupMCP", instructions="SketchUp Ruby evaluation and selection inspection", lifespan=server_lifespan)

@mcp.tool()
def get_selection(ctx: Context) -> str:
    """Get currently selected components in SketchUp"""
    try:
        sketchup = get_sketchup_connection()
        result = sketchup.send_command(method="tools/call", params={"name": "get_selection", "arguments": {}}, request_id=ctx.request_id)
        return json.dumps(result)
    except Exception as e:
        return f"Error getting selection: {str(e)}"

@mcp.tool()
def eval_ruby(ctx: Context, code: str) -> str:
    """Evaluate Ruby code in SketchUp"""
    try:
        sketchup = get_sketchup_connection()
        result = sketchup.send_command(method="tools/call", params={"name": "eval_ruby", "arguments": {"code": code}}, request_id=ctx.request_id)
        text = result.get("content", [{"text": "Success"}])[0].get("text", "Success") if isinstance(result.get("content"), list) and result.get("content") else "Success"
        return json.dumps({"success": True, "result": text})
    except Exception as e:
        return json.dumps({"success": False, "error": str(e)})

def main():
    mcp.run()

if __name__ == "__main__":
    main()
