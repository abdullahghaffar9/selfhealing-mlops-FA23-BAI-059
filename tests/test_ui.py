import pytest
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

def test_frontend_sentiment():
    chrome_options = Options()
    chrome_options.add_argument("--headless")
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-dev-shm-usage")
    chrome_options.binary_location = "/usr/bin/chromium"

    # Point directly to the system-installed driver
    service = Service(executable_path="/usr/bin/chromedriver")

    driver = webdriver.Chrome(service=service, options=chrome_options)
    driver.get("http://localhost:5000")

    input_box = driver.find_element(By.ID, "text-input")
    input_box.send_keys("A masterpiece of storytelling with complex characters.")

    driver.find_element(By.ID, "submit-btn").click()

    # Explicitly wait for the result
    wait = WebDriverWait(driver, 10)
    result_element = wait.until(EC.visibility_of_element_located((By.ID, "result-output")))

    output_text = result_element.text
    driver.quit()

    assert output_text != ""
    assert "POSITIVE" in output_text or "NEGATIVE" in output_text
