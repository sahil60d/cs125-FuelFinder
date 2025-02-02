//
//  SearchView.swift
//  project
//

import SwiftUI
import Foundation

struct Dish: Codable {
    let name: String
    let calories: Double
    let fat: Double
    let protein: Double
    let sugar: Double
    let carbs: Double
}
struct SearchView: View {
    let boxGrey = Color(hex: 0x404040)
    let textGrey = Color(hex: 0x999999)
    
    @State private var searchText: String = ""
    @State private var dishes: [Dish] = []
    
    var body: some View {
        VStack{
            VStack
            {
                HStack{
                    Spacer()
                    Image(systemName: "magnifyingglass").resizable().foregroundColor(textGrey)
                        .padding(.horizontal, 2)
                        .frame(width: 40, height: 40)
                    TextField("Search", text: $searchText)
                        .padding()
                        .textFieldStyle(CustomRoundedBorderTextFieldStyle())
                        .padding(.horizontal, 2)
                    
                }.padding()
                
                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(dishes, id: \.name) { dish in
                            PreviewBox(color:boxGrey, dish: dish)
                        }
                    }
                    .padding()
                }
                
                
            }.background(Color.black)
            Spacer()
        }.background(Color.black)
            .onAppear{dishes = loadDishes()}
        .onChange(of: searchText) {
            dishes = search(query:searchText, dish_array:dishes)
                }
    }
    
    func loadJSONData(from filename: String) -> [String: Any]? {
        if let url = Bundle.main.url(forResource: filename, withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                // convert json data to any object
                let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                //print("json object:")
                //print(jsonObject)
                
                // convert any object to [String: Any] dictionary
                guard let jsonDictionary = jsonObject as? [String: Any] else {
                    print("Error converting to dictionary")
                    return nil
                }
                
                //print("json dictionary:")
                //print(jsonDictionary)
                
                return jsonDictionary
            } catch {
                print("[!] error loading json data: \(error.localizedDescription)")
                return nil
            }
        } else {
            print("[!] file not found")
            return nil
        }
    }
    
    func loadDishes(debug: Bool=false) -> [Dish] {
        var dishDataArray = [Dish]()
        
        let jsonDictionary = loadJSONData(from: "dishes")
        for (dishName, nutritionInformation) in jsonDictionary ?? [:] {
            guard let nutritionDict = nutritionInformation as? [String: Any],
                  let calories = nutritionDict["calories"] as? Double,
                  let fat = nutritionDict["fat"] as? Double,
                  let protein = nutritionDict["protein"] as? Double,
                  let sugar = nutritionDict["sugar"] as? Double,
                  let carbs = nutritionDict["carbs"] as? Double else {
                continue
            }
            let dishData = Dish(name: dishName, calories: calories, fat: fat, protein: protein, sugar: sugar, carbs: carbs)
            dishDataArray.append(dishData)
        }
        
        if debug == true {
            for dish in dishDataArray{
                print("Dish Name: \(dish.name)")
                print("Calories: \(dish.calories)")
                print("Fat: \(dish.fat)")
                print("Protein: \(dish.protein)")
                print("Sugar: \(dish.sugar)")
                print("Carbs: \(dish.carbs)\n")
            }
        }
        return dishDataArray
    }
    
    func search(query: String, dish_array: [Dish]) -> [Dish]
    {
        print(query)
        
        // for string in query
        var score = [(Double, Dish)]()
        for dish in dish_array{
            // calculate distances
            let lev_score = levenshteinDistanceScore(string1: query, string2: dish.name)
            score.append((lev_score, dish))
        }
        // sort and return highest distance
        let sortedScore = score.sorted { $0.0 > $1.0 }
        
        var sortedDishArray = [Dish]()
        for (_, dish) in sortedScore
        {
            sortedDishArray.append(dish)
        }
        
        return sortedDishArray
    }
    
    func levenshteinDistanceScore(string1: String, string2: String) ->
        // based on solution graciously provided by Ankit Rathi at https://stackoverflow.com/questions/47794688/closest-match-string-array-sorting-in-swift
        Double {
            var s1 = string1.lowercased()
            var s2 = string2.lowercased()

            s1 = s1.trimmingCharacters(in: .whitespacesAndNewlines)
            s2 = s2.trimmingCharacters(in: .whitespacesAndNewlines)
            
            let empty = [Int](repeating:0, count: s2.count)
            var last = [Int](0...s2.count)

            for (i, t_lett) in s1.enumerated() {
                var current = [i + 1] + empty
                for (j, s_lett) in s2.enumerated() {
                    current[j + 1] = t_lett == s_lett ? last[j] : Swift.min(last[j], last[j + 1], current[j])+1
                }
                last = current
            }

            let lowestScore = max(s1.count, s2.count)

            if let validDistance = last.last {
                return  1 - (Double(validDistance) / Double(lowestScore))
            }

            return 0.0
        }
    
    struct PreviewBox: View {
        var color: Color
        var dish: Dish
        
        var body: some View {
            Button(action: {
                print("selected preview: " + dish.name + "\n\tCalories: " + String(Int(dish.calories)))
            }) {
                HStack {
                    Image(systemName: "photo.on.rectangle")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 120)
                        .padding()
                        .foregroundColor(.white)
                    Text(dish.name)
                        .font(.system(size:26))
                        .foregroundColor(.white)
                    Spacer()
                }
                .background(color)
                .cornerRadius(10)
            }
        }
    }
    
    struct CustomRoundedBorderTextFieldStyle:
        TextFieldStyle {
        let boxGrey = Color(hex: 0x404040)
        let textGrey = Color(hex: 0x999999)

        func _body(configuration: TextField<Self._Label>) -> some View {
            configuration
                .frame(width: .infinity, height: 75)
                .padding(.horizontal, 10) // Padding inside the text field
                .background(RoundedRectangle(cornerRadius: 8).stroke(boxGrey, lineWidth: 2).foregroundColor(.white))
                // Custom border style
                .foregroundColor(.white) // Text color
                .font(.system(size:30)) // Text font
            
        }
    }
}

#Preview {
    SearchView()
}
