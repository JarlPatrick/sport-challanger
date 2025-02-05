const amplifyconfig = '''{
  "auth": {
    "plugins": {
      "awsCognitoAuthPlugin": {
        "UserAgent": "aws-amplify-cli/2.0",
        "Version": "1.0",
        "identityManager": {
          "Default": {}
        },
        "CognitoUserPool": {
          "Default": {
            "PoolId": "eu-north-1_4vbSo9nap",
            "AppClientId": "1hbco4eovg1ceip8p4ep0vgtng",
            "AppClientSecret": "v9ma3phg7i2okuackc99p9cq6m6qmi92ngh8oshec7ddqpm00q5",
            "Region": "eu-north-1"
          }
        },
        "Auth": {
          "Default": {
              "authenticationFlowType": "USER_SRP_AUTH",
              "socialProviders": [],
              "usernameAttributes": [],
              "signupAttributes": [
                  "EMAIL",
                  "NAME"
              ],
              "passwordProtectionSettings": {
                  "passwordPolicyMinLength": 8,
                  "passwordPolicyCharacters": [
                      "REQUIRES_LOWERCASE",
                      "REQUIRES_UPPERCASE",
                      "REQUIRES_NUMBERS",
                      "REQUIRES_SYMBOLS"
                  ]
              },
              "mfaConfiguration": "OFF",
              "mfaTypes": [],
              "verificationMechanisms": [
                  "EMAIL"
              ]
          }
        }
      }
    }
  }
}''';
