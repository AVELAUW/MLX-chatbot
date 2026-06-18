// ────────────────────────────────────────────────────────────
//  SECTION 9: Loops & Functions
//  A for-in loop repeats code once for each item in a collection.
//  A while loop repeats code as long as a condition stays true.
//  A func is a reusable block of code you can call by name.
//  Functions can take parameters (inputs) and return a value (output).
// ────────────────────────────────────────────────────────────

for rapper in bestRappers {
    print(rapper)   // prints each name in bestRappers, one by one
}

var countdown = 3
while countdown > 0 {
    print(countdown)
    countdown -= 1   // shrinks countdown each time, or this loop never ends!
}

func greet(name: String) -> String {
    return "Hello, \(name)!"
}

print(greet(name: "Swift"))   // prints "Hello, Swift!"

// TODO: Write a for-in loop that prints every item in YOUR
//       favoriteFoods array from Section 5

// TODO: Write a while loop that counts up from 1 to 5

// TODO: Write a function called double(number: Int) -> Int
//       that returns the number multiplied by 2

// TODO: Call your double function with a number of your choice
//       and print the result

// TODO: Write a function called isOldEnough(age: Int) -> Bool
//       that returns true if age is 13 or older, false otherwise
