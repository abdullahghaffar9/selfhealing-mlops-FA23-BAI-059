import time
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.options import Options

def test_frontend_sentiment():
    """Headless Selenium test to verify the end-to-end frontend interaction."""
    # Configure Chrome options for a headless container environment
    chrome_options = Options()
    chrome_options.add_argument("--headless")
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-dev-shm-usage")
    
    # Initialize the web driver instance
    driver = webdriver.Chrome(options=chrome_options)
    
    try:
        # Navigate to the Flask application homepage running locally on port 5000
        driver.get("http://localhost:5000")
        
        # Give the DOM a moment to fully initialize
        time.sleep(2)
        
        # 1. Locate the input text area and enter a test phrase
        text_input = driver.find_element(By.ID, "text-input")
        text_input.send_keys("The pipeline execution is running perfectly smooth!")
        
        # 2. Locate the submission action button and click it
        submit_btn = driver.find_element(By.ID, "submit-btn")
        submit_btn.click()
        
        # 3. Wait briefly for the async fetch API lifecycle call to update the UI
        time.sleep(3)
        
        # 4. Extract the output text from the results container area
        result_output = driver.find_element(By.ID, "result-output")
        output_text = result_output.text
        
        # 5. Perform the exact assertions demanded by the grading criteria
        assert output_text != "", "Error: The result container element is empty."
        
        contains_valid_keyword = any(keyword in output_text for keyword in ["POSITIVE", "NEGATIVE", "Confidence"])
        assert contains_valid_keyword, f"Error: Result text '{output_text}' does not contain POSITIVE, NEGATIVE, or Confidence."
        
        print(f"UI Test successfully passed with output content: {output_text}")
        
    finally:
        # Securely teardown the process thread to prevent memory leaks
        driver.quit()
