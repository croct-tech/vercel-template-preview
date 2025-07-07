# Croct template

This repository provides a **project scaffold template** for Vercel deployments.
It contains a minimal `vercel.json` and a `scaffold.sh` script that automatically sets up your project when Vercel deploys it.

## How it works

When you deploy this template with Vercel:

* Vercel clones this repository.
* The `scaffold.sh` script runs automatically to generate the project structure using the specified template.
* The generated project is built and deployed.

## Running locally

If you want to generate the project locally:

1. Pull your Vercel project settings:

```bash
vercel pull
```
2. Run the scaffold script:

```bash
./scaffold.sh
```

The script uses environment variables to determine which template to use.

## Explore other templates

For more templates, check out the [Croct template catalog](https://croct.com/templates). 
