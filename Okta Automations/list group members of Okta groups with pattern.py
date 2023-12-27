# This script outputs to CSV all group members of Okta groups that contain a specific word
import requests
import csv

# Okta API base URL
OKTA_API_BASE_URL = "INSERTtoken"

# Okta API key (replace with your API key)
OKTA_API_KEY = "INSERTAPIKey"

# Headers for Okta API request
headers = {
    "Authorization": f"SSWS {OKTA_API_KEY}",
    "Accept": "application/json",
    "Content-Type": "application/json",
}

def get_groups():
    # Get a list of all groups that contain the prefix
    prefix="EnterPrefix"
    groups_url = f"{OKTA_API_BASE_URL}/groups?q={prefix}&limit=100"
    response = requests.get(groups_url, headers=headers)

    if response.status_code == 200:
        return response.json()
    else:
        print(f"Error fetching groups: {response.text}")
        return None

def get_group_members(group_id):
    # Get members of a specific group
    members_url = f"{OKTA_API_BASE_URL}/groups/{group_id}/users"
    response = requests.get(members_url, headers=headers)

    if response.status_code == 200:
        return response.json()
    else:
        print(f"Error fetching group members: {response.text}")
        return None

def main():
    # Get all groups that start with "Okta test"
    groups = get_groups()
    # Write group names and IDs to a CSV file
    csv_file_path = "/pathtocsv.csv"

    if groups:
        with open(csv_file_path, mode="w", newline="", encoding="utf-8") as csv_file:
            csv_writer = csv.writer(csv_file)
            csv_writer.writerow(["Group Name", "User ID", "User Email"])

            for group in groups:
                group_name = group["profile"]["name"]
                group_id = group["id"]

                # Get members of the group
                members = get_group_members(group_id)

                if members:
                    for member in members:
                        user_id = member["id"]
                        user_email = member["profile"]["email"]
                        csv_writer.writerow([group_name, user_id, user_email])

    print("Script completed successfully.")

if __name__ == "__main__":
    main()
