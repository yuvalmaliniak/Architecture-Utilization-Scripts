# This script use Okta API Calls in order to get all Okta groups for list of Okta apps

import requests
import csv
import json


# Okta API base URL
OKTA_API_BASE_URL = "INSERTtoken"

# Okta API key (replace with your API key)
OKTA_API_KEY = "INSERTAPIKey"

def get_group_name(groupID):
    endpoint_url = f"{OKTA_API_BASE_URL}/groups/{groupID}"

    # Headers for Okta API request
    headers = {
        "Authorization": f"SSWS {OKTA_API_KEY}",
        "Accept": "application/json",
        "Content-Type": "application/json",
    }
    # API call
    response = requests.get(endpoint_url, headers=headers)
    if response.status_code == 200:
        group_name = response.json().get("profile", {}).get("name", "")
        return group_name
    else:
        print(f"Failed to retrieve groups for app {app_id}. Status code: {response.status_code}")
        return ""


def get_okta_groups_for_app(app_id):
    # Okta API endpoint to get app groups
    endpoint_url = f"{OKTA_API_BASE_URL}/apps/{app_id}/groups"

    # Headers for Okta API request
    headers = {
        "Authorization": f"SSWS {OKTA_API_KEY}",
        "Accept": "application/json",
        "Content-Type": "application/json",
    }

    # Make the Okta API request
    response = requests.get(endpoint_url, headers=headers)

    # Check if the request was successful
    if response.status_code == 200:
        return response.json()
    else:
        print(f"Failed to retrieve groups for app {app_id}. Status code: {response.status_code}")
        return None

def main():
    # List of Okta apps
    okta_apps = [ {"id": "Enter APPID", "name": "APP Name"}, {"id": "Enter APPID", "name": "APP Name"}
    # Output CSV file
    output_csv_file = "/pathtocsv/okta_groups_output.csv"

    # Header for the output CSV
    csv_header = ["App Name", "App ID", "Group Name"]

    with open(output_csv_file, mode="w", newline="") as output_file:
        csv_writer = csv.writer(output_file)
        csv_writer.writerow(csv_header)

        for app in okta_apps:
            app_id = app["id"]
            app_name = app["name"]

            # Get Okta groups for the current app
            app_groups = get_okta_groups_for_app(app_id)

            if app_groups:
                for group in app_groups:
                    group_id = group.get("id", "")
                    group_name = get_group_name(group_id)
                    csv_writer.writerow([app_name, app_id, group_name])

            else:
                print(f"Failed to retrieve groups for {app_name} (App ID: {app_id}).")

if __name__ == "__main__":
    main()
