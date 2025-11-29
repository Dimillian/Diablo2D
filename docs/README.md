# Beads Task Tracker - GitHub Pages

This directory contains a static web page that displays all beads issues from the `.beads/issues.jsonl` file.

## Setup GitHub Pages

1. Go to your repository settings on GitHub
2. Navigate to **Pages** in the left sidebar
3. Under **Source**, select **Deploy from a branch**
4. Choose **main** (or your default branch) and **/docs** folder
5. Click **Save**

The page will be available at: `https://<your-username>.github.io/<repo-name>/`

## How it works

The `index.html` file fetches the `.beads/issues.jsonl` file from the repository root and displays all issues in a nice, filterable UI.

## Features

- **Statistics Dashboard**: Shows total issues, open/closed counts, and epic count
- **Filtering**: Filter by status, type, and priority
- **Search**: Search issues by title, description, or ID
- **Dependency Visualization**: Shows issue dependencies and relationships
- **Responsive Design**: Works on desktop and mobile devices

## Updating

The page automatically reads from `.beads/issues.jsonl`, so whenever you update your beads issues (via `bd` commands), the page will reflect those changes after the next GitHub Pages deployment.
