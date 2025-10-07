#!/bin/bash
# Quick script to push the 404 fix to GitHub

set -e

echo "=================================================="
echo "Pushing RunPod 404 Fix to GitHub"
echo "=================================================="
echo ""

echo "📋 Changes to be pushed:"
echo "  - Added /health endpoint for Docker healthcheck"
echo "  - Fixed port environment variable precedence"
echo ""

echo "🔄 Pushing to GitHub..."
git push origin main

echo ""
echo "✅ Push complete!"
echo ""
echo "=================================================="
echo "Next Steps:"
echo "=================================================="
echo ""
echo "1. Go to RunPod dashboard"
echo "2. STOP your current pod"
echo "3. START it again (pulls latest code)"
echo "   OR create a new pod from your template"
echo ""
echo "4. Wait ~2-3 minutes for startup"
echo ""
echo "5. Test the fix:"
echo "   curl https://YOUR-RUNPOD-URL/health"
echo "   curl https://YOUR-RUNPOD-URL/docs"
echo ""
echo "Expected: Both should work! 🎉"
echo "=================================================="

