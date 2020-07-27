Ensure to set the following environment variables in your shell profile when
using the [aws][1] or [eb][2] Amazon Command Line interfaces.

```
AWS_DEFAULT_PROFILE=<your-aws-user-name>
AWS_DEFAULT_REGION="us-east-1"
AWS_ACCESS_KEY_ID="..."
AWS_SECRET_ACCESS_KEY="..."
AWS_EB_PROFILE="${AWS_DEFAULT_PROFILE}"
```
[1]: https://aws.amazon.com/cli/
[2]: http://docs.aws.amazon.com/elasticbeanstalk/latest/dg/eb-cli3.html