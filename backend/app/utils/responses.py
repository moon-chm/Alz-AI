from typing import Any, Optional
from fastapi.responses import JSONResponse
from fastapi.encoders import jsonable_encoder

def success_response(data: Any = None, message: str = "Success", status_code: int = 200) -> JSONResponse:
    """Wraps successful data in the mandatory { success, data, error } contract"""
    return JSONResponse(
        status_code=status_code,
        content=jsonable_encoder({
            "success": True,
            "data": data,
            "message": message,
            "error": None
        })
    )

def error_response(message: str, error_detail: Any = None, status_code: int = 400) -> JSONResponse:
    """Wraps error details in the mandatory { success, data, error } contract"""
    return JSONResponse(
        status_code=status_code,
        content=jsonable_encoder({
            "success": False,
            "data": None,
            "message": message,
            "error": error_detail
        })
    )
