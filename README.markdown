Application that adds iPizza payment gateway to Ecwid with small hack using e-Path payment gateway settings in Ecwid store.

Parameters provided by Ecwid
============================

* **ord** A unique order number (19)
* **des** What the customer is buying or "Online Order" for brevity (Manolo Shoes)
* **amt** The amount the customer is paying and authorising you to charge (49.95)
* **frq** The charge frequency (Once, monthly etc), not relevant in this context
* **ceml** Customer email address (foo@bar.com)
* **ret** A return URL (the URL to return after payment is done) (https://store.mysite.com)

Test submit file
================

To emulate form submitted from ecwid, simply use this html file:

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
