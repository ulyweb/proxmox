>[!NOTE]
> ## Set up Gmail as the SMTP server in your Nextcloud All-in-One (AIO) instance. 
>>Since Gmail now requires **App Passwords** (especially if 2FA is enabled), you’re on the right track.
>>Here's what you should enter under **Administration > Basic settings > Email Server** in Nextcloud:

---

### ✅ **SMTP Settings for Gmail with App Password**

| Field                     | Value                                                            |
| ------------------------- | ---------------------------------------------------------------- |
| **Send mode**             | SMTP                                                             |
| **Encryption**            | `ssl` or `tls` (recommended: `tls`)                              |
| **From address**          | your Gmail email (e.g. `yourname@gmail.com`)                     |
| **Authentication method** | Login                                                            |
| **Server address**        | `smtp.gmail.com:587` (for TLS) or `smtp.gmail.com:465` (for SSL) |
| **Credentials required**  | ✅ (check it)                                                     |
| **SMTP username**         | your full Gmail address (e.g. `yourname@gmail.com`)              |
| **SMTP password**         | the Gmail **App Password** (not your Google password!)           |

---

### ✅ Steps Recap:

1. Go to: **Nextcloud Admin Settings → Basic Settings → Email Server**
2. Select `SMTP` as the send mode.
3. Choose `TLS` encryption.
4. Enter:

   * Gmail email address
   * SMTP server: `smtp.gmail.com`
   * Port: `587` (for TLS) or `465` (for SSL)
   * SMTP Username: your Gmail address
   * SMTP Password: your Gmail **App Password** (generated at [https://myaccount.google.com/apppasswords](https://myaccount.google.com/apppasswords))
5. Click **Send email** (test message) to confirm it's working.

---

### ⚠️ Notes:

* Google blocks “less secure apps” now, so **App Passwords are required** if you use 2FA.
* If you don’t see the App Password option, ensure 2-Step Verification is enabled on your account.

---

Let me know if you'd like help troubleshooting an error or configuring Gmail to send from a different address.
