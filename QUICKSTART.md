# 🚀 Quick Start Instructions

## ✅ Your Repository is Ready!

All files are committed and ready to push to GitHub.

---

## 📋 Step-by-Step Instructions

### **Step 1: Create GitHub Repository**

1. **Go to:** https://github.com/new

2. **Fill in:**
   - **Repository name:** `azure-hybrid-worker-lab`
   - **Description:** `Complete Terraform lab for Azure Automation Hybrid Worker with managed identities`
   - **Visibility:** Public ✅ (or Private if you prefer)
   - **⚠️ IMPORTANT:** Do NOT check any boxes for README, .gitignore, or license

3. **Click:** "Create repository"

4. **Copy the repository URL** shown on the next page (looks like: `https://github.com/YOUR_USERNAME/azure-hybrid-worker-lab.git`)

---

### **Step 2: Push to GitHub**

**In PowerShell (in this directory), run:**

```powershell
# Add remote (replace YOUR_USERNAME with your actual GitHub username)
git remote add origin https://github.com/YOUR_USERNAME/azure-hybrid-worker-lab.git

# Rename branch to main
git branch -M main

# Push to GitHub
git push -u origin main
```

**Example:**
```powershell
git remote add origin https://github.com/petarivanov/azure-hybrid-worker-lab.git
git branch -M main
git push -u origin main
```

---

### **Step 3: Deploy from Azure Cloud Shell**

1. **Open Azure Cloud Shell:**
   - Go to: https://shell.azure.com
   - Or click the Cloud Shell icon `>_` in Azure Portal
   - Choose **Bash** when prompted

2. **Clone and deploy:**

```bash
# Clone your repository (replace YOUR_USERNAME)
git clone https://github.com/YOUR_USERNAME/azure-hybrid-worker-lab.git
cd azure-hybrid-worker-lab

# Make deployment script executable
chmod +x deploy-cloudshell.sh

# Run the automated deployment script
./deploy-cloudshell.sh
```

**Or deploy manually:**

```bash
# Initialize Terraform
terraform init

# Deploy everything (~7-10 minutes)
terraform apply -auto-approve

# View results
terraform output
```

---

## 📁 Files Included in Repository

| File | Purpose |
|------|---------|
| `main.tf` | Complete Terraform configuration (22 resources) |
| `variables.tf` | Customizable deployment parameters |
| `outputs.tf` | 14 useful outputs after deployment |
| `README.md` | Main documentation for GitHub |
| `GUIDE.md` | Comprehensive user guide |
| `SETUP_GUIDE.md` | Detailed setup instructions |
| `README_TECHNICAL.md` | Technical documentation |
| `run-test-runbook.ps1` | Helper script for manual runbook testing |
| `setup-github.ps1` | This setup helper |
| `deploy-cloudshell.sh` | Automated deployment script for Cloud Shell |
| `.gitignore` | Git ignore rules |

---

## 🎯 What Gets Deployed

- ✅ Windows VM (Windows Server 2022)
- ✅ Azure Automation Account
- ✅ Hybrid Worker Group & Registration
- ✅ PowerShell modules (Az.Accounts, Az.Compute)
- ✅ Test runbook with managed identity authentication
- ✅ Automated testing
- ✅ Complete networking (VNet, Subnet, NSG, Public IP)
- ✅ Managed identities with Contributor role

**Total:** 22 resources in ~7-10 minutes

---

## 💰 Cost Warning

Resources cost approximately **$38/month** if VM runs 24/7.

**⚠️ IMPORTANT:** Run `terraform destroy -auto-approve` when finished to avoid charges!

---

## 📖 Documentation

- **Quick Start:** `README.md`
- **Complete Guide:** `GUIDE.md`
- **Setup Instructions:** `SETUP_GUIDE.md`
- **Technical Details:** `README_TECHNICAL.md`

---

## 🆘 Need Help?

1. **Setup Issues:** See `SETUP_GUIDE.md`
2. **Deployment Issues:** See `GUIDE.md` → Troubleshooting section
3. **GitHub Issues:** Check you didn't initialize the repo with README

---

## ✅ Checklist

Before pushing to GitHub:
- [ ] Created GitHub repository
- [ ] Did NOT initialize with README
- [ ] Copied repository URL
- [ ] Updated commands with YOUR_USERNAME

After pushing to GitHub:
- [ ] Repository visible on GitHub
- [ ] All files present
- [ ] README.md displays correctly

Ready for Cloud Shell:
- [ ] Opened Azure Cloud Shell
- [ ] Cloned repository
- [ ] In correct subscription
- [ ] Ready to run `./deploy-cloudshell.sh`

---

**Happy Deploying! 🎉**
