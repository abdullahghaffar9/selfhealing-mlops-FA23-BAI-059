FROM python:3.10-slim

# Set the working directory inside the container
WORKDIR /app

# Copy the requirements file first to utilize Docker layer caching
COPY requirements.txt .

# Install dependencies cleanly without saving cache to keep image size minimal
RUN pip install --no-cache-dir -r requirements.txt

# Copy the application source code and frontend template layout
COPY app.py .
COPY templates/ templates/

# Create the dedicated persistent directory for prediction logs
RUN mkdir -p /app/logs

# Expose the internal port the Flask application binds to
EXPOSE 5000

# Execute the application python entry point script
CMD ["python", "app.py"]
