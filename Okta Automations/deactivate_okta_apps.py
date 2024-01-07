# This script receives from csv a list of Okta apps and disables them. 
# Please note that there is a org-wide rate limit for bulk deletion (Status code 429)- https://developer.okta.com/docs/reference/rate-limits/#:~:text=If%20any%20org%2Dwide%20rate,checking%20Okta's%20rate%20limiting%20headers
# Input: List of IDs of Okta apps in a csv file containing 1 column
# Output: the script outputs status codes during the process
import requests
import csv

# Okta API base URL
OKTA_API_BASE_URL = "https://YOURORG.okta.com/api/v1"

# Okta API key (replace with your API key)
OKTA_API_KEY = "YOURTOKEN"

# Headers for Okta API request
headers = {
    "Authorization": f"SSWS {OKTA_API_KEY}",
    "Accept": "application/json",
    "Content-Type": "application/json",
}

def deactivate_app(app_id):
    # Delete an Okta app with the app_id 
    app_url = f"{OKTA_API_BASE_URL}/apps/{app_id}/lifecycle/deactivate"
    
    # Use POST method to deactivate
    response = requests.post(app_url, headers=headers)
    if response.status_code == 200:
        print(f"App with ID {app_id} deactivated successfully.")
    else:
        print(f"Failed to deactivate app with ID {app_id}. Status code: {response.status_code}")

def main():
    # read csv
    csv_file_path = "/pathtocsv/applist.csv"
    with open(csv_file_path, 'r') as csv_file:
        csv_reader = csv.DictReader(csv_file)
        # Use the line below to define the fill name of your column. This is used to prevent text decoding mistakes.
        # You can delete this line after testing it and ensuring the column's name
        print(f"CSV Header: {csv_reader.fieldnames}")
        for row in csv_reader:
            app_id = row['ENTER COLUMN NAME HERE'].strip()
            deactivate_app(app_id)
    print("Script completed successfully.")

if __name__ == "__main__":
    main()
