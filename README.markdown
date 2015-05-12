This application adds Estonian banks ([iPizza payment](https://github.com/Voog/ipizza) gateway) to [Ecwid](http://www.ecwid.com) with small hack using [e-Path](http://kb.ecwid.com/e-Path) payment gateway settings in Ecwid store.

If Ecwid Order API code is added to app config then Ecwid order is delivered/cancelled over [Order API](http://help.ecwid.com/customer/portal/articles/1166917) when payment is delivered/cancelled.

# App configuration

App can be customized by using environmental variables. Check out configuration variable names in configuration files:

* [config/application.yml](./config/application.yml) - defaults for application variables.
* [config/banks.yml](./config/banks.yml) - defaults for iPizza, EstCard and PayPal providers.
* [config/secrets.yml](./config/secrets.yml) - defaults for secrets.

Minimum set of environmental variables for production environment:

* `ECWIDSHOP_SHOP_NAME="My eShop"`
* `ECWIDSHOP_SHOP_EXTERNAL_URL=http://example.com`
* `ECWIDSHOP_SHOP_EXTERNAL_RETURN_URL=http://example.com/cart`
* `ECWIDSHOP_MAILER_DEFAULT_FROM="Ecwid eShop <store@example.com>"`
* `ECWIDSHOP_MAILER_NOTIFICATION_EMAIL=store@example.com`
* `ECWIDSHOP_SECRET_KEY_BASE=long-random-string-3274y23472384y237842y73hwerbhjwfbjhsdbfsygf7r3gfs`
* `ECWIDSHOP_PROVIDER_RETURN_HOST=https://shop.example.com`
* `ECWIDSHOP_ECWID_SHOP_ID=123445`
* `ECWIDSHOP_ECWID_ORDER_API_KEY=kjujujhyhyh`

At least one bank should be enabled (e.g. `ECWIDSHOP_BANK_SWEDBANK_ENABLED=true`) and configured (see [config/banks.yml](./config/banks.yml)).

To setup database configuration run `bin/setup` to instal gems and copy `config/database.sample.yml` to `config/database.yml`.

# Setup in Ecwid

Add a new [e-Path](http://kb.ecwid.com/e-Path) payment method to your Ecwid account. Point it's url to your app.

If you want the user to choose the payment method in this application manually then use this general url:

```
https://shop.example.com/payments
```

Or you can add more than one e-Path payment methods to your Ecwid account - one by each enabled payment method (bank). If selected provider is enabled in app then user is automatically redirected to given provider.

Supported endpoints:

```
https://shop.example.com/payments/swedbank
https://shop.example.com/payments/seb
https://shop.example.com/payments/lhv
https://shop.example.com/payments/sampo
https://shop.example.com/payments/krediidipank
https://shop.example.com/payments/nordea
https://shop.example.com/payments/estcard
https://shop.example.com/payments/paypal
```

You can also enable automatic detection by Ecwid shopping cart paymentMethod name. To use auto detection then you need to set your e-Path url to "auto" endpoint:

```
https://shop.example.com/payments/auto
```

and your payment method names should be match one of enabled bank name (accepted values "SEB", "SEB pank", "SEB bank").

Get your [Ecwid Shop ID](http://help.ecwid.com/customer/portal/articles/1083303-how-to-get-your-store-id) and find your Ecwid Order API key. You can generate this secret key in Ecwid Control Panel, section System Settings → Apps → [Legacy API key](https://my.ecwid.com/cp/CP.html#apps:view=legacy_api).

## Parameters provided by Ecwid

* `ord` A unique order number (`19`)
* `des` What the customer is buying or "Online Order" for brevity (`Manolo Shoes`)
* `amt` The amount the customer is paying and authorising you to charge (`49.95`)
* `frq` The charge frequency (`Once`, `monthly` etc), not relevant in this context
* `ceml` Customer email address (`foo@bar.com`)
* `ret` A return URL (the URL to return after payment is done) (`https://store.mysite.com`)

# App management

Payments listing and current configuration of the app can be seen in `https://shop.example.com/admin` by using authentication credentials from configuration (`ECWIDSHOP_AUTHENTICATION_USERNAME` and `ECWIDSHOP_AUTHENTICATION_PASSWORD`).

# Optional discount validation

Application supports optional Ecwid discount code validation using [Ecwidy API v3](http://api.ecwid.com).

Usage:

```
/discounts/MYCODE
```

It returns existing active [discount code object](http://api.ecwid.com/#search-coupons). Otherwise it returns not found response.

**Setup:**

Request access to [Ecwid API v3](http://api.ecwid.com#register-your-app-in-ecwid). You need access to `read_discount_coupons` scope.

Login to your Ecwid account.

**Step 1.** Go to  Ecwid's oAuth endpoint to get access authorize your app. Enter the url:

```
https://my.ecwid.com/api/oauth/authorize?client_id=MY-CLIENT-ID&redirect_uri=http%3A%2F%2Fwww.myshop.com%2Fapi&response_type=code&scope=read_discount_coupons
```

**Step 2.** You are redirected to url specified in `redirect_uri` parameter. Grab the code form response url. Example:

```
http://www.myshop.com/api?code=SOME-RANDOM-CODE
```


**Step 3.** Retrieve access_token from Ecwid

```
curl "https://my.ecwid.com/api/oauth/token" \
-XPOST \
-d client_id=MY-CLIENT-ID \
-d client_secret=CLIENT-SECRET-KEY \
-d code=SOME-RANDOM-CODE \
-d redirect_uri=http%3A%2F%2Fwww.myshop.com%2Fapi \
-d grant_type=authorization_code
```

Example response:

```
{
  "access_token": "MY-APP-ACCESS-TOKEN-FOR-DISCOUNTS",
  "token_type": "Bearer",
  "scope":"read_store_profile read_discount_coupons",
  "store_id": 11111
}
```

**Step 4.** Updated your `application.yml` file to enableAPI 3 access

```
ECWIDSHOP_ECWID_API3_ACCESS_TOKEN: "MY-APP-ACCESS-TOKEN-FOR-DISCOUNTS"
```

# Deploying application

Application has predefined [Capistrano](https://github.com/capistrano) tasks and some example scripts ([config/deploy/example_app.rb](./config/deploy/example_app.rb) and [config/deploy/example_app](./config/deploy/example_app)).

Add your deployment environment:

```
config
|--- deploy
|--- |--- my_shop
|--- |--- |--- production.rb
|--- |--- my_shop.rb
```

Add configuration for your environment (see example environment):

```
custom
|--- my_shop
|--- |--- config
|--- |--- |--- certificates
|--- |--- |--- |--- estcard_live.crt
|--- |--- |--- |--- seb_bank_cert.pem
|--- |--- |--- |--- my_shop_key.pem
|--- |--- |--- application.yml
|--- |--- |--- banks.yml
|--- |--- |--- database.yml
|--- |--- my_shop.rb
```

Check your server environment:

```
bundle exec cap my_shop:production check_write_permissions
```

Setup your custom configuration (see [example environment](./config/deploy/example_app.rb)):

```
bundle exec cap my_shop:production deploy:upload_configuration
```

Deploy your application:

```
bundle exec cap my_shop:production deploy
```

# Server setup

Note: For using environmental variables. Ensure that your web server is using UTF-8 encoding for environmental variables.

## Example setup for Apache2.

Disable default `LANG=C` value and enable system default.

```
sudo nano /etc/apache2/envvars
```

```
...

## The locale used by some modules like mod_dav
# export LANG=C
## Uncomment the following line to use the system default locale instead:
. /etc/default/locale

...
```

# Testing

## Test submit file

To emulate form submitted from Ecwid, simply use this html file:

```
<!DOCTYPE html>
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
  <title>Ecwid pizzeria test submit</title>
</head>
<body>
  <form action="/payments" method="post">
    <input type="hidden" name="ret" value="http://app.ecwid.com/e-path/123456" />
    <input type="hidden" name="ceml" value="foo@bar.com" />
    <input type="hidden" name="ord" value="1" />
    <input type="hidden" name="frq" value="Once" />
    <input type="hidden" name="des" value="Startup beer(1), Exit beer(1)" />
    <input type="hidden" name="opt" value="685991;1290662631" />
    <input type="hidden" name="amt" value="11.00" />
    <input type="submit" value="Submit new payment" />
  </form>
</body>
</html>
```

## Test credit cards for EstCard payment method

```
Mastercard: 5450339000000014
Valid: 0915 (MMYY)
CVV2/CVC: 432

VISA: 4761739001010010
Valid: 1212 (MMYY)
CVV2: 780
```
