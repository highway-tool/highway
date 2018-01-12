# Credential Store

Highway has a built in way to handle credentials. At the moment the support for credentials is very limited. You can only have at most a single credential for each highway project. A credential itself is also very limited: It is only a combination of user and password/secret.

---
**GOOD TO KNOW**

The password/secret is stored in the macOS Keychain and managed by the `highway` command line tool automatically.

---

## Creating a Credential
Creating a credential is a two step process.

### 1st.: Override `defaultUser()` in your `Highway`-subclass.
Override `defaultUser()` and return a user name whose corresponding password/secret you need in your highway project. For example:

```
final class App: Highway<Way> {
    override func defaultUser() -> String? {
        return "my_apple_developer_id@example.org"
    }
    // ...
}
```

### 2nd.: Create the Password/Secret
As mentioned in the introduction, the credential is managed by the highway command line tool. This also includes the creation of new credentials. Simply execute `highway` (without any arguments) in the directory which contains your highway project. `highway` automatically knows that you return something in your implementation of `defaultUser()` and tries to find it in your keychain. If the corresponding item cannot be found in your keychain, `highway` will ask you to enter a password/secret. So, all you have to do is to enter your password/secret and hit enter. You only have to do that once (or if you decide to manually delete the created keychain item).

## Using the Credential
Your highway has a property called `credentialStore` (type: `CredentialStore`).

If you specify a `defaultUser` (by overriding `defaultUser()`) and if the corresponding keychain item exists then you can access the password by calling `credentialStore.password()`.
