# core/logging.py
import json, logging, os, sys

class JsonFormatter(logging.Formatter):
    def format(self, record: logging.LogRecord) -> str:
        payload = {
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
            "time": self.formatTime(record, self.datefmt),
        }
        # Attach extras (request_id, path, etc.)
        for key in ("request_id", "path", "method", "status_code", "duration_ms"):
            if hasattr(record, key):
                payload[key] = getattr(record, key)
        if record.exc_info:
            payload["exc_info"] = self.formatException(record.exc_info)
        return json.dumps(payload, ensure_ascii=False)

def configure_logging():
    root = logging.getLogger()
    # Lambda already sets a handler; replace format for consistency
    for h in list(root.handlers):
        root.removeHandler(h)

    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(JsonFormatter())

    level = "INFO"
    root.setLevel(level)
    root.addHandler(handler)

    # Quiet noisy loggers if needed
    logging.getLogger("botocore").setLevel(logging.WARNING)
    logging.getLogger("uvicorn").propagate = True
    logging.getLogger("uvicorn.access").propagate = True
