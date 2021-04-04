# Charge! (timon.de.lamps3)

A simple Flutter game. Based on no particular state management. Including code for multiplayer based on firebase (Firestore & Cloud Functions).
Very nice theming included too. Published on Google Play: https://play.google.com/store/apps/details?id=timon.de.lamps3

# Development
I developed this little game during the 2020 spring lockdown. It is actually the 3rd iteration of developing a chain reaction game. It was one of my first completely web compatible projects.
The code is somewhat janky, since it does not feature any state management. Yet the Ui, mainly based on buttons and dialogs, is straight forward and easy to edit. The theme.dart was the first of its kind I used during development and finalizing. The game mechanics are all living inside game.dart. The game state is stored here and calculated forward. The game.dart and online.dart objects are inherited by their creators.

# Future
The online game and local multiplayer didn't make it into the final version. Nevertheless, the code is still available. Hence, I may end up readding them. The firebase endpoint should still be accessible too.
