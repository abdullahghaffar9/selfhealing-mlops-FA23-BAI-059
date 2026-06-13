import pytest
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

def test_frontend_sentiment():
    # Setup Headless Chrome
    chrome_options = Options()
    chrome_options.add_argument("--headless")
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-dev-shm-usage")
    
    driver = webdriver.Chrome(options=chrome_options)
    
    # URL of your running app
    driver.get("http://localhost:5000")
    
    # Define test data
    test_text = "A masterpiece of storytelling with complex characters and beautifully crafted prose"
    
    # Interact with elements
    input_box = driver.find_element(By.ID, "text-input")
    input_box.send_keys(test_text)
    
    submit_btn = driver.find_element(By.ID, "submit-btn")
    submit_btn.click()
    
    # Wait for result and assert
    wait = WebDriverWait(driver, 10)
    result = wait.until(EC.presence_of_element_located((By.ID, "result-output")))
    
    output_text = result.text
    
    assert output_text != ""
    assert any(x in output_text for x in ["POSITIVE", "NEGATIVE", "Confidence"])
    
    driver.quit()
