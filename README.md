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

## Development

### Dependencies

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

You also need to have a Docker daemon running if you attempt to deploy. The
first deploy may take a long time as the Docker image used to compile native
gems is downloaded.

### Test

Run the tests

```
bundle exec rspec
```

To debug a test, add `require "debug";debugger` in the code to create a breakpoint.


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

On the App Settings page, go to **OAuth & Permissions** (may be in the sidebar)

> You can ignore the parts about Token Rotation and Redirect URLs. That is only
useful when you are using a Slack app that will be shared across workspaces.
Currently pr-check assumes you will create a new app for every workspace where
you want to use it, so there is no need for a User OAuth authentication
(but you _will_ add OAuth scopes - I know, that is a little confusing).

Scroll down to **Scopes**. There is a section for _Bot Token Scopes_ and a section
for _User Token Scopes_. pr-check does not use User Tokens at all, so make sure
you perform the following steps in the _Bot Token Scopes_ section.
Click the **Add an OAuth Scope** button to add these scopes:

```
reactions:write
links:read
```

Go back to the **Basic Information** section for your app. Click _Install to Workspace_.

You will see the OAuth approval page confirming you want to grant the permissions
to the app. Click **Allow**

You should be brought back to the **Basic Information** section. You can optionally
scroll down to **Display Information** to add a description, and possibly an icon,
so that others in your workspace know what the app does.

Now go back to the **OAuth & Permissions** section. You should now see a
_Bot User OAuth Token_. Copy this value, as it is the value you will set as
the `SLACK_TOKEN` environment variable when you deploy.

Keep the Slack app settings page open in your browser, as you will return to it
soon.

#### Deploy the app:

From your command line in this repository's directory:

```
SLACK_TOKEN=your-bot-token serverless deploy -s production
```

When the deploy finishes, the output will contain a list of `endpoints`.
Copy the URL that ends with `slack`.

#### Back in the Slack app settings page

Go to the **Event Subscriptions** page from the sidebar.
- Toggle _Enable Events_ to `On`
- Paste in the URL from the deploy that ends with `slack` as the _Request URL_
- Expand the _Subscribe to bot events_ section, click _Add Bot User Event_ and
choose `link_shared`
- At the bottom of the page under _App Unfurl Domains_, click Add Domain
- Enter `github.com` and click Done

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
