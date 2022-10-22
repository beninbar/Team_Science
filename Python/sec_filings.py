"""
Pulling data from the SEC Filings api.
https://www.sec.gov/edgar/sec-api-documentation

Will pull data for a few larger Fortune 500 companies.
Ideally we'd want to 
"""
import requests

def get_submission(cik):
    """
    Get submission data from SEC filings endpoint

    parameters:
        cik: str or int; Central Index Key/Company Identifier outlined by SEC Filings API
    """
    url = f"https://data.sec.gov/submissions/{cik}.json"
    r = requests.get(url)
    print(r.text)
    return r.text

if __name__ == "__main__":
    company_ciks = {
                    "Apple Inc": 320193,
    
                   }
    for company, cik  in company_ciks.items():

        txt = get_submission(cik)

        print("-------------------")