// Q4 - MongoDB Solutions
// File: q4_mongodb_solution.js
// Database: alpha
// Usage: run in mongosh or mongo shell connected to your database.
// Example: mongosh alpha --file q4_mongodb_solution.js

// --- 0) Insert the given entries into collection `books`
db.books.drop();

db.books.insertMany([
    { book_id: "B001", title: "Data Science Fundamentals", author: "John Smith", category: "Technology", price: 29.99, in_stock: true },
    { book_id: "B002", title: "Learning MongoDB", author: "Jane Doe", category: "Technology", price: 35.99, in_stock: false },
    { book_id: "B003", title: "Web Development with JavaScript", author: "Mark Lee", category: "Programming", price: 24.99, in_stock: true },
    { book_id: "B004", title: "Introduction to Python", author: "Alice Brown", category: "Programming", price: 19.99, in_stock: true },
    { book_id: "B005", title: "Advanced SQL Queries", author: "Michael White", category: "Database", price: 45.99, in_stock: true },
    { book_id: "B006", title: "C++ Basics", author: "John Smith", category: "Programming", price: 29.99, in_stock: true },
    { book_id: "B007", title: "Machine Learning with Python", author: "Sara Green", category: "Technology", price: 39.99, in_stock: true },
    { book_id: "B008", title: "Deep Learning Essentials", author: "David Grey", category: "Technology", price: 59.99, in_stock: false },
    { book_id: "B009", title: "Data Structures in Java", author: "Lucas Blue", category: "Programming", price: 49.99, in_stock: true },
    { book_id: "B010", title: "Artificial Intelligence", author: "Sophia Grey", category: "Technology", price: 69.99, in_stock: true }
]);

// View inserted documents
print('Initial documents:');
db.books.find().pretty();

// --------------------------------------------------
// 1) Update the price of all books in the "Technology" category
//    that have a price less than $40, and set the in_stock value to false.
//    (set price unchanged, only set in_stock:false as instruction says "and set the in_stock value to false")
// If you instead wanted to increase price, modify accordingly.

db.books.updateMany(
    { category: "Technology", price: { $lt: 40 } },
    { $set: { in_stock: false } }
);

// --------------------------------------------------
// 2) Delete a book where the book_id is "B008" and it is out of stock (in_stock: false).

db.books.deleteOne({ book_id: "B008", in_stock: false });

// --------------------------------------------------
// 3) Update the price of books by "John Smith" in the "Technology" category to $35,
//    but only if the price is greater than $20 and the book is in stock.

db.books.updateMany(
    { author: "John Smith", category: "Technology", price: { $gt: 20 }, in_stock: true },
    { $set: { price: 35 } }
);

// --------------------------------------------------
// 4) Find all books from the "Programming" category with a price greater than $25,
//    and where the in_stock value is true. Sort them by price in descending order.

print('\nProgramming books price > 25 and in stock, sorted by price desc:');
var res4 = db.books.find({ category: "Programming", price: { $gt: 25 }, in_stock: true }).sort({ price: -1 });
res4.forEach(printjson);

// --------------------------------------------------
// 5) Delete all books that are either in the "Programming" category and out of stock (in_stock: false),
//    or have a price greater than $50.

db.books.deleteMany({ $or: [{ category: "Programming", in_stock: false }, { price: { $gt: 50 } }] });

// --------------------------------------------------
// 6) Update the price of books with book_id "B005" and "B006" to $40, and set their in_stock value to true.

db.books.updateMany(
    { book_id: { $in: ["B005", "B006"] } },
    { $set: { price: 40, in_stock: true } }
);

// --------------------------------------------------
// 7) Find all books where the author is "Jane Doe" or the category is "Database",
//    and the price is between $30 and $60.

print('\nBooks where author is Jane Doe OR category is Database, price between $30 and $60:');
db.books.find({
    $or: [{ author: "Jane Doe" }, { category: "Database" }],
    price: { $gte: 30, $lte: 60 }
}).pretty();

// --------------------------------------------------
// 8) Update the price of all books in the "Programming" category to $50,
//    only if their current price is less than $50 and they are currently in stock.

db.books.updateMany(
    { category: "Programming", in_stock: true, price: { $lt: 50 } },
    { $set: { price: 50 } }
);

// --------------------------------------------------
// 9) Delete all books where the price is less than $30 and the category is "Technology",
//    and their in_stock value is false.

db.books.deleteMany({ category: "Technology", price: { $lt: 30 }, in_stock: false });

// --------------------------------------------------
// 10) Update the title of the book with book_id "B010" to "AI Revolution", and reduce its price by 10%.
// Use aggregation pipeline update (requires MongoDB 4.2+ / mongosh):

db.books.updateOne(
    { book_id: "B010" },
    [
        { $set: { title: "AI Revolution", price: { $multiply: ["$price", 0.9] } } }
    ]
);

// --------------------------------------------------
// Final view of collection
print('\nFinal documents after operations:');
db.books.find().pretty();

// End of Q4 solutions

db.books.find(
    {$and: [
        {
        $or: [{
            author: "Jane Doe"
        },
            {
            category: "Database"
        }]
        },
        {
            $and: [
                {price: {$gt: 30}},
                {price: {$lt: 60}}
            ]
        }
    ]}
)