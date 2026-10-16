# Unhide POS SoftPOS — paste this prompt in Cursor

Copy everything below the line and send it as your message:

---

POS app mai sara SoftPOS wala kaam unhide kardo:

1. `fliter-service-provider 2/lib/config/pos_softpos_feature.dart` mein `kPosSoftPosFrontendEnabled` ko `true` karo.
2. Orders Hub app bar se SoftPOS pill/widget wapas show karo (`OrdersHubSoftPosAppBarAction`).
3. Order review screen par SoftPOS settings row wapas show karo.
4. Invoice aur Request Payment flows mein SoftPOS connection guard aur card-terminal bridge wapas enable karo (`SoftPosConnectionGuard`, `runSoftPosBeforeInvoice`, `runSoftPosRequestPayment`).
5. Orders Hub par "Request Payment" button wapas show karo.
6. Card payment option enabled hi rehna chahiye (Edit Customer Details / payment dialog mein disable mat karna).

Sirf frontend/feature-flag changes; backend SoftPOS APIs ko touch mat karna unless zaroorat ho.
