

// object

var youtubeVideo = {
  "title": "How",
  "duration" : 10,
  "isHD" : true,
  "thumbnail" : "https://www.youtube.com/thumbnail.jpg",
  "authorName" : "John Doe"
};

void main() {
  var muffin = 300;
  var muffinEaten = 2;
  var totalCalories = muffin * muffinEaten; // -- 600 calories
  print("Total Calories: $totalCalories");
  var name = "Ambittious Alim";

  // int/number
  var age = 27;

  // boolean
  var isMale = true;
  var isMinor = age < 18;

  var fruits = ["apple", "banana", "orange"];
  var orange = fruits [2];
  // key/value pairs
  var resturant = {
    "name" : "McDonalds",
    "location" : "New York",
    "rating" : 4.5
  };

  bool isAdult = !isMinor;
  if (isAdult){
    print("welcome to the website");
  } else {
    print("You are not allowed to enter");
  }

  var shoeProducts = [{"name": "Nike", "price": 150}, 
  {"name": "Adidas", "price":100}, 
  {"name": "Vans Old Skool" , "price": 80} ];
  
  for (var product = 0; product < shoeProducts.length; product++){
    print("${shoeProducts[product]["name"]} price is \$${shoeProducts[product]["price"]}\n");

  }
}

