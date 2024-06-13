import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CocktailSearchPage(),
    );
  }
}

class CocktailSearchPage extends StatefulWidget {
  @override
  _CocktailSearchPageState createState() => _CocktailSearchPageState();
}

class _CocktailSearchPageState extends State<CocktailSearchPage> {
  String searchText = "";
  List<dynamic> drinks = [];
  List<String> favoriteDrinksIds = [];

  Future<void> fetchCocktails(String searchTerm) async {
    final response = await http.get(
      Uri.parse(
          "http://www.thecocktaildb.com/api/json/v1/1/search.php?s=$searchTerm"),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data["drinks"] != null) {
        setState(() {
          drinks = data["drinks"];
        });
      } else {
        drinks = [];
      }
    } else {
      print("Failed to load cocktails: ${response.statusCode}");
    }
  }

  Future<void> _loadFavoritesFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteDrinkIds = prefs.getStringList('favoriteDrinkIds');
    if (favoriteDrinkIds != null) {
      setState(() {
        favoriteDrinksIds = favoriteDrinkIds;
      });
    }
  }

  Future<void> _saveFavoritesToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favoriteDrinkIds', favoriteDrinksIds);
  }

  void addToFavorites(Map<String, dynamic> cocktail) {
    final String id = cocktail['idDrink'];
    if (!favoriteDrinksIds.contains(id)) {
      setState(() {
        favoriteDrinksIds.add(id);
        _saveFavoritesToStorage();
      });
    }
  }

  void _toggleFavorite(Map<String, dynamic> cocktail) {
    final String id = cocktail['idDrink'];
    setState(() {
      if (favoriteDrinksIds.contains(id)) {
        favoriteDrinksIds.remove(id);
      } else {
        favoriteDrinksIds.add(id);
      }
      _saveFavoritesToStorage();
    });
  }

  @override
  void initState() {
    super.initState();
    _loadFavoritesFromStorage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cocktail Search'),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: "Search for Cocktails",
                icon: Icon(Icons.search),
              ),
              onChanged: (text) {
                setState(() {
                  searchText = text;
                });
              },
              onSubmitted: (text) => fetchCocktails(text),
            ),
          ),
          Expanded(
            child: drinks.isEmpty
                ? Center(child: Text('No cocktails found'))
                : GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10.0,
                      mainAxisSpacing: 10.0,
                    ),
                    itemCount: drinks.length,
                    itemBuilder: (context, index) {
                      final drink = drinks[index];
                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CocktailDetailScreen(
                              cocktail: drink,
                              isFavorite:
                                  favoriteDrinksIds.contains(drink['idDrink']),
                              onToggleFavorite: _toggleFavorite,
                            ),
                          ),
                        ),
                        child: Container(
                          padding: EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Image.network(
                                  drink["strDrinkThumb"],
                                  fit: BoxFit.cover,
                                ),
                              ),
                              SizedBox(
                                  height:
                                      8.0), // Add spacing between image and text
                              Text(
                                drink["strDrink"],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  favoriteDrinksIds.contains(drink['idDrink'])
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: Colors.red,
                                ),
                                onPressed: () => _toggleFavorite(drink),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class CocktailDetailScreen extends StatelessWidget {
  final Map<String, dynamic> cocktail;
  final bool isFavorite;
  final Function(Map<String, dynamic>) onToggleFavorite;

  CocktailDetailScreen(
      {required this.cocktail,
      required this.isFavorite,
      required this.onToggleFavorite});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(cocktail["strDrink"]),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              cocktail["strDrinkThumb"],
              width: 200,
              height: 200,
              fit: BoxFit.cover,
            ),
            SizedBox(height: 20),
            Text(
              "Ingredients:",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            ..._buildIngredientsList(cocktail),
            SizedBox(height: 20),
            Text(
              "Instructions:",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              cocktail["strInstructions"],
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: Colors.red,
              ),
              onPressed: () => onToggleFavorite(cocktail),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildIngredientsList(Map<String, dynamic> cocktail) {
    List<Widget> ingredientsWidgets = [];
    for (int i = 1; i <= 15; i++) {
      final ingredient = cocktail["strIngredient$i"];
      final measure = cocktail["strMeasure$i"];
      if (ingredient != null && ingredient.trim().isNotEmpty) {
        ingredientsWidgets.add(
          Text(
            "$ingredient: $measure",
            style: TextStyle(fontSize: 16),
          ),
        );
      }
    }
    return ingredientsWidgets;
  }
}
