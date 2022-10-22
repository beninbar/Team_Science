"""
Pulling data from the SEC Filings api.
https://www.sec.gov/edgar/sec-api-documentation

Will pull data for a few larger Fortune 500 companies.
Ideally we'd want to 
"""
import requests
import os
import json
import pandas as pd

# Free API keys can be downloaded here
# https://sec-api.io/signup/free
SEC_API_KEY = os.environ.get("SEC_API_KEY")

def get_submission(cik):
    """
    Get submission data from SEC filings endpoint

    parameters:
        cik: str or int; Central Index Key/Company Identifier outlined by SEC Filings API
    """
    url = f"data.sec.gov/api/xbrl/companyfacts/{cik}.json" #f"https://data.sec.gov/submissions/{cik}.json"
    r = requests.get(url)

    return r.text

def get_compensation(cik):
    """Pulls executive compensation data for a given company cia the SEC API
    
    parameters:
        cik: int or str; Central Index Key to identify company being queried
    """
    url = f"https://api.sec-api.io/compensation/{cik}?token={SEC_API_KEY}"

    return requests.get(url)

if __name__ == "__main__":
    company_ciks = {
                    "Apple Inc": 320193,
    
                   }
    for company, cik  in company_ciks.items():

        comp = get_compensation(cik)
        comp_json = comp.json()

        df = pd.json_normalize(comp_json)
        print(pd.json_normalize(comp_json))

        print("-------------------")