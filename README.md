# PR Check

Monitors Slack for messages that refer to a Pull Request. When that Pull Request
is approved, adds a reaction emoji to each of the messages that mentioned it.

## How it works

1. Slack sends a POST to the service's `/slack` endpoint any time a `github.com` URL is mentioned.
The service records that mention as Pull Request URL, the Slack channel the message was posted in,
and the timestamp of the message (which is Slack's unique identifier).

2. GitHub sends a POST to the service's `/github` endpoint any time a Pull Request is approved.
The service records the Pull Request URL as an approval.

3. The system makes an API call to Slack to add a reaction emoji to each mention of an approved Pull Request.

> * Note that steps 1 and 2 can happen in any order, and both will trigger step 3.

## Development requirements

Install serverless globally

```
npm install -g serverless
```

Install the serverless plugins

```
yarn install
```

Install the ruby gems

```
bundle install --standalone --path vendor/bundle
```

## Deployment

> Make sure you follow the instructions for Initial Deployment Configuration
below, if the app has not been setup in Slack or Github yet.

You must specify a Slack OAuth token via `SLACK_TOKEN` environment variable
when deploying. The token must have access to add reactions to messages.

```
SLACK_TOKEN=12345 serverless deploy --stage production
```

## Initial Deployment Configuration

### Configure Slack

Go to Slack to [create a new application](https://api.slack.com/apps?new_app=1)

In the Create a Slack App dialog:

App Name: pr_check

Development Slack Workspace: <choose your workspace>

On the App Settings page, go to OAuth & Permissions

Scroll down to Scopes and add:

```
reactions:write # under Reactions
links:read      # under Unfurls
```

Click Save Changes

Scroll to the top of the page and click Install App to Workspace

You will see the OAuth approval page confirming you want to grant the permissions
to the app. Click Authorize.

You should now see an OAuth Access Token at the top of the page. This is the
value you need to set in the `SLACK_TOKEN` environment variable when you deploy.

Deploy the app:

```
SLACK_TOKEN=yourtoken serverless deploy -s production
```

When the deploy finishes, the output will contain a list of `endpoints`.
Copy the URL that ends with `slack`.

Back in the Slack app settings page, go to Basic Information
Click Add features and functionality
Click Event Subscriptions
Click to Enable Events
Paste in the URL from the deploy that ends with `slack`
Click Add Workspace Event, choose link_shared
At the bottom of the page under App Unfurl Domains, click Add Domain
Enter `github.com` and click Done
Click Save Changes

### Configure Github

Open Github, go to Organization settings or settings for an individual Repository

Go to Webhooks

Click Add Webhook

In Payload URL, enter the endpoint from the deploy output that ends in `github`

Change the Content type to `application/json`

Enter a Secret. We will eventually use this value to verify the hook validity.

For "which events" choose "Let me select individual events"

Uncheck Pushes

Check "Pull request reviews".

This should be the only event checked.

Click Add Webhook button

Github will send a test ping (click on the webhook to see the Recent Deliveries)

The service is now ready, watching for pull request mentions and approvals.
