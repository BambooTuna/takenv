```
source .env && xurl auth apps add myapp --client-id $X_CLIENT_ID --client-secret $X_CLIENT_SECRET
REDIRECT_URI=http://localhost:8089/callback xurl auth oauth2 --app myapp
xurl auth default myapp
xurl auth status
xurl whoami

```
