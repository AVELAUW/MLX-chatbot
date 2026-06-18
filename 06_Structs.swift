// ────────────────────────────────────────────────────────────
//  SECTION 6: Structs
//  A struct is a blueprint that groups related data together.
//  You define it once, then create as many copies as you need.
// ────────────────────────────────────────────────────────────

struct Rapper {
    var name: String
    var age: Int
    var favAlbum: String
}

var drake = Rapper(name: "Drake", age: 37, favAlbum: "Take Care")
print(drake.name)   // prints "Drake"

// TODO: Create another Rapper using the struct above (pick any artist!)
//       e.g., var kendrick = Rapper(name: "Kendrick Lamar", age: 36, favAlbum: "DAMN.")

// TODO: Print the favAlbum of the Rapper you just created

// TODO: Create your OWN struct called Student with these three properties:
//         - name            (String)
//         - grade           (Int)
//         - favoriteSubject (String)

// TODO: Create a Student variable using your new struct and fill in real values

// TODO: Print the name property of your Student
