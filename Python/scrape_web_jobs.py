from selenium import webdriver 
from selenium.webdriver import Chrome
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.support.ui import Select
import json
import re, time
from collections import defaultdict
import onepass


def open_weblink(weblink):
    '''
    Inputs: User inputted link for Linkedin webpage
    Outputs: Returns a Browser instance
    Purpose: Open Google Chrome automated instance based on user inputted link and user must have chrome driver in PATH
    '''
    opts = Options()
    driver = webdriver.Chrome(options=opts)
    driver.get(weblink)
    return driver


def pull_linkedin_job_pane_links(wp):
    '''
    Inputs: Browser instance
    Outputs: List of data scientist job links on LinkedIn
    Purpose: Load left pane job results and pull each page link for keyword data scientist job openings
    '''
    job_result_list = wp.find_element_by_xpath('//ul[@class="jobs-search__results-list"]')
    jobs = job_result_list.find_elements_by_xpath('.//div[contains(@class,"base-card")]')
    data_sci_links = [job.find_element_by_xpath('.//a').get_attribute('href') for job in jobs if re.search('.*Data Scientist.*',job.find_element_by_xpath('.//h3').text)]
    return data_sci_links

def pull_linkedin_job_details(wp,job_link):
    '''
    Inputs: Link for individual data science role
    Outputs: Parsed job opening details in dictionary
    Purpose: Scrape relevant information from job description on LinkedIn
    '''
    wp.execute_script("window.scrollTo(0,0)")
    wp.get(job_link)
    time.sleep(1)
    show_more_button = wp.find_element_by_xpath('//button[@class="show-more-less-html__button show-more-less-html__button--more"]')
    show_more_button.click()
    time.sleep(1)
    job_details = defaultdict()
    job_details['link'] = job_link
    job_details['job_description'] = wp.find_element_by_xpath('//h2').text
    job_details['company'] = wp.find_element_by_xpath('//span[@class="topcard__flavor"]').text
    job_details['location'] = wp.find_element_by_xpath('//span[@class="topcard__flavor topcard__flavor--bullet"]').text
    criterion = wp.find_elements_by_xpath('//li[@class="description__job-criteria-item"]')
    job_criteria = {criteria.text.splitlines()[0]:criteria.text.splitlines()[1] for criteria in criterion}
    job_details.update(job_criteria)
    description = wp.find_element_by_xpath('.//div[@class="description__text description__text--rich"]')
    paragraphs = description.find_elements_by_xpath('.//p')
    job_details['job_paragraphs'] = [paragraph.text for paragraph in paragraphs if paragraph != '']
    bullets = description.find_elements_by_xpath('.//li')
    job_details['job_bullets'] = [bullet.text for bullet in bullets if bullet != '']
    
    return job_details

def create_json_output(jd_data,source):
    with open(f'{source}_job_description_data.json', 'w', encoding='utf-8') as f:
        json.dump(jd_data, f, ensure_ascii=False,indent=4)

def scrape_linkedin():
    '''
    Inputs: None
    Outputs: List of defaultdict dictionaries with Linkedin job description data
    Purpose: Grab data scientists job postings from LinkedIn.com

    '''
    linkedin_link = 'https://www.linkedin.com/jobs/data-scientist-jobs?position=1&pageNum=0'
    browser = open_weblink(linkedin_link)
    jds = pull_job_pane_links(browser)
    job_listings = []
    browser.close()

    for i,jd in enumerate(jds):
        browser = open_weblink(jd)
        job_listings.append(pull_job_details(wp=browser,job_link=jd))
        time.sleep(3)
        browser.close()
    create_json_output(jd_data=job_listings,source='LinkedIn')

def pull_indeed_job_links(driver, jobs):
    '''
    Inputs: Google Chrome browser instance and list for tracking the postings
    Outputs: List of defaultdict dictionaries that are tracking Indeed job postings
    Purpose: Pull in indeed job data scientist links as well as basic information on posting
    '''
    job_pane = driver.find_element_by_xpath('//div[@class="jobsearch-LeftPane"]')
    job_listings = job_pane.find_elements_by_xpath('.//div[@class="job_seen_beacon"]')
    for job_listing in job_listings:
        
        job_link = job_listing.find_element_by_xpath('.//a')
        if re.search('.*Data Scientist.*',job_link.find_element_by_xpath('.//span').text):
            job_details = defaultdict()
            job_details['job_description'] = job_link.find_element_by_xpath('.//span').text
            job_details['link'] = job_link.get_attribute('href')
            job_details['company'] = job_listing.find_element_by_xpath('.//span[@class="companyName"]').text
            try:
                salary_detail = job_listing.find_element_by_xpath('.//div[@class="heading6 tapItem-gutter metadataContainer noJEMChips salaryOnly"]')
                job_details['salary'] = job_listing.find_element_by_xpath('.//div[@class="metadata salary-snippet-container"]').text
                job_details['Employment type'] = job_listing.find_element_by_xpath('.//div[@class="metadata"]').text

            except:
                job_details['salary'] = None

            job_details['location'] = job_listing.find_element_by_xpath('.//div[@class="companyLocation"]').text.splitlines()[0]
            jobs.append(job_details)
    return jobs

def pull_indeed_job_detail(driver,jobs):
    '''
    Inputs: Google Chrome browser instance and list of data science postings
    Outputs: List of defaultdict dictionaries with Indeed job posting details
    Purpose: Pull in remaining job posting detail from Indeed job links
    '''

    new_job_listings = []
    for job in jobs:
        driver.get(job['link'])
        if 'Employment type' not in job.keys():
            header = driver.find_elements_by_xpath('//div[@class="jobsearch-JobDescriptionSection-sectionItem"]')
            if len(header)==0:
                job['Employment type'] = None
            elif len(header) == 1:
                job['Employment type'] = header[0].text.splitlines()[1]
            else:
                job['Employment type'] = [head.text.splitlines()[1] for idx, head in enumerate(header) if idx==1][0]
        job_data = driver.find_element_by_xpath('//div[@id="jobDescriptionText"]')
        paragraphs = job_data.find_elements_by_xpath('.//p')
        job['job_paragraphs'] = [paragraph.text for paragraph in paragraphs if paragraph.text != '']
        bullets = job_data.find_elements_by_xpath('.//li')
        job['job_bullets'] = [bullet.text for bullet in bullets if bullet.text !='']
        new_job_listings.append(job)
    return new_job_listings


def scrape_indeed():
    '''
    Inputs: None
    Outputs: List of defaultdict dictionaries with two pages of Indeed
    Purpose: Grab data scientists job postings from Indeed.com

    '''
    indeed_link = 'https://www.indeed.com/q-Data-Scientist-jobs.html?vjk=40d3b79ead743d59'
    open_weblink(indeed_link)
    jobs = []
    jobs = pull_indeed_job_links(driver=driver,jobs=jobs)

    pagination = driver.find_element_by_xpath('//a[@data-testid="pagination-page-2"]')
    pagination.click()
    jobs = pull_indeed_job_links(driver=driver,jobs=jobs)
    full_job_detail = pull_indeed_job_detail(driver,jobs)
    create_json_output(jd_data=job_listings,source='LinkedIn')

if __name__ == '__main__':

    scrape_linkedin()
    scrape_indeed()
