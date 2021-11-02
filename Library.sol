// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract BooksLibrary is Ownable {

    using SafeMath for uint16;
    using SafeMath for uint;

    struct Book {
        string name;
        uint16 copies;
        uint16 timesBorrowed;
        string author;
        string id;
    }

    struct History {
        address user;
        uint borrowedAt;
        uint returnedAt;
        string bookName;
    }

    mapping (string => Book) books;
    mapping (string => mapping(address => bool)) bookToBorrowers;
    mapping (string => History[]) borrowHistory;
    string[] booksIds;
    
    // events
    event onBookAdded(Book book);
    event onBookBorrowed(address from, string bookName);
    event onBookReturned(address from, string bookName);

    // build book id by concatenating book name an its author
    function _buildId(string memory _name, string memory _author) private pure returns (string memory) {
        return string(abi.encodePacked(_name, _author));
    }

    // function that compare two strings for equality
    function _compareStrings(string memory _a, string memory _b) private pure returns (bool) {
        return keccak256(abi.encodePacked(_a)) == keccak256(abi.encodePacked(_b));
    }
    
    // function that check whether book id exists
    function isBookNotPresent(string memory _id) private view returns (bool) {
        return bytes(books[_id].id).length == 0;
    }

    // modifier validating the input when book is added
    modifier isBookInputValid(string memory _name, string memory _author) {
        require(bytes(_name).length != 0, "Book name cannot be empty.");
        require(bytes(_author).length != 0, "Author cannot be empty.");
        _;
    }
    modifier isBookOwner(string memory _id) {
        require(bookToBorrowers[_id][msg.sender], "You should be the owner of the book.");
        _;
    }

    // function that creates a book by given input and add it to the library. It can be invoked only by the owner of the smart contract.
    function addBook(string memory _name, uint16 _copies, string memory _author) external isOwner isBookInputValid(_name, _author) {
        string memory id = _buildId(_name, _author);
        require(isBookNotPresent(id), "Book already exist.");
        if(_copies == 0) {
            _copies = 1;
        }
        books[id] = Book(_name, _copies, 0, _author, id);
        booksIds.push(id);
        emit onBookAdded(books[id]);
    }

    function _handleBorrow(Book storage book) private {
        bookToBorrowers[book.id][msg.sender] = true;
        book.timesBorrowed = uint16(book.timesBorrowed.add(1));
        History memory record = History(msg.sender, block.timestamp, 0, book.name);
        borrowHistory[book.name].push(record);
        emit onBookBorrowed(msg.sender, book.name);
    }

    // function that initialize book tracking
    function borrowBook(string memory _id) external {
        Book storage book = books[_id];
        require(!isBookNotPresent(book.id), "Book not exist.");
        require(book.timesBorrowed < book.copies, "Book is not available.");
        bool alreadyBorrowed = bookToBorrowers[book.id][msg.sender];
        require(!alreadyBorrowed, "You already borrow this book.");
        _handleBorrow(book);
    }

    function _handleReturn(Book storage book) private {
        bookToBorrowers[book.id][msg.sender] = false;
        book.timesBorrowed = uint16(book.timesBorrowed.sub(1));
        History[] storage records = borrowHistory[book.name];
        uint recordsCount = records.length - 1;
        for(uint i = recordsCount; i >= 0; i--) {
            History storage history = records[i];
            if(history.user == msg.sender) {
                history.returnedAt = block.timestamp;
                emit onBookReturned(msg.sender, book.name);
                break;
            }
        }
    }

    // function that interrupts book tracking
    function returnBook(string memory _id) external isBookOwner(_id){
        bool isBorrowed = bookToBorrowers[_id][msg.sender];
        require(isBorrowed, "The Book has been returned already.");
        Book storage book = books[_id];
        _handleReturn(book);
    }

    // function that returns all availbale books
    function getAvailableBooks() public view returns (Book[] memory) {
        uint booksCount = booksIds.length;
        Book[] memory result = new Book[](booksCount);
        uint trackCount = 0;
        for(uint i = 0; i < booksCount; i++) {
            string memory bookId = booksIds[i];
            Book memory book = books[bookId];
            if(book.timesBorrowed < book.copies) {
                result[trackCount] = book;
                trackCount = trackCount.add(1);
            }
        }

        return result;
    }

    // function that returns all history records by given book name
    function getBookBorrowHistory(string memory _name) public view returns (History[] memory) {
        return borrowHistory[_name];
    }
}