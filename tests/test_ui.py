import pytest
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait

def test_frontend_sentiment():
    chrome_options = Options()
    chrome_options.add_argument("--headless")
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-dev-shm-usage")
    driver = webdriver.Chrome(options=chrome_options)
    driver.get("http://localhost:5000")

    input_box = driver.find_element(By.ID, "text-input")
    input_box.send_keys("A masterpiece of storytelling with complex characters and beautifully crafted prose")
    
    driver.find_element(By.ID, "submit-btn").click()

    # Explicitly wait for the backend to return a result before checking
    wait = WebDriverWait(driver, 10)
    wait.until(lambda d: d.find_element(By.ID, "result-output").text.strip() != "")

    output_text = driver.find_element(By.ID, "result-output").text
    driver.quit()

    assert output_text != ""
    assert "POSITIVE" in output_text or "NEGATIVE" in output_text
