# Basic Item CRUD App/Dockerfile
FROM public.ecr.aws/lambda/python:3.12

WORKDIR ${LAMBDA_TASK_ROOT}

# Install Python deps
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
# (Assumes this Dockerfile sits beside main.py and the app folders)
COPY . .

# Make sure Python can import from the task root
ENV PYTHONPATH=${LAMBDA_TASK_ROOT}

# Lambda handler
CMD ["main.handler"]
