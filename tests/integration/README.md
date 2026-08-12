Integration tests — require a running server.

    uvicorn app.main:app --reload
    pytest tests/integration
