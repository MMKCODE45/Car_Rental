-- Drop existing tables with CASCADE CONSTRAINTS
DROP TABLE Payment CASCADE CONSTRAINTS;
DROP TABLE Reservation CASCADE CONSTRAINTS;
DROP TABLE Bus CASCADE CONSTRAINTS;
DROP TABLE Car CASCADE CONSTRAINTS;
DROP TABLE Vehicle CASCADE CONSTRAINTS;
DROP TABLE Category CASCADE CONSTRAINTS;
DROP TABLE Customer CASCADE CONSTRAINTS;

-- Create Customer table
CREATE TABLE Customer (
    customerID NUMBER PRIMARY KEY,
    name VARCHAR2(50),
    email VARCHAR2(50),
    address VARCHAR2(100),
    phone VARCHAR2(15),
    driverLicenseNumber VARCHAR2(20)
);

-- Create Category table
CREATE TABLE Category (
    categoryID NUMBER PRIMARY KEY,
    categoryName VARCHAR2(50)
);

-- Create VehicleType as OBJECT
CREATE TYPE VehicleType AS OBJECT (
    vehicleID NUMBER,
    make VARCHAR2(50),
    model VARCHAR2(50),
    year NUMBER,
    registrationNumber VARCHAR2(20),
    availabilityStatus VARCHAR2(20)
);


-- Create Vehicle table using VehicleType
CREATE TABLE Vehicle OF VehicleType (
    PRIMARY KEY (vehicleID),
    UNIQUE (registrationNumber),
    availabilityStatus NOT NULL,
    CHECK (availabilityStatus IN ('Available', 'Unavailable')),
    CHECK (year >= 1886) -- The year the first car was invented
);

-- Create Car table
CREATE TABLE Car (
    vehicleID NUMBER PRIMARY KEY,
    categoryID NUMBER,
    CONSTRAINT fk_car_vehicle FOREIGN KEY (vehicleID) REFERENCES Vehicle (vehicleID),
    CONSTRAINT fk_car_category FOREIGN KEY (categoryID) REFERENCES Category (categoryID)
);

-- Create Bus table
CREATE TABLE Bus (
    vehicleID NUMBER PRIMARY KEY,
    seatingCapacity NUMBER,
    busType VARCHAR2(50),
    categoryID NUMBER,
    CONSTRAINT fk_bus_vehicle FOREIGN KEY (vehicleID) REFERENCES Vehicle (vehicleID),
    CONSTRAINT fk_bus_category FOREIGN KEY (categoryID) REFERENCES Category (categoryID)
);

-- Create ReservationType as OBJECT
CREATE TYPE ReservationType AS OBJECT (
    reservationID NUMBER,
    reservationDate DATE,
    rentalStartDate DATE,
    rentalEndDate DATE,
    totalAmount NUMBER,
    vehicleID NUMBER,
    registrationNumber VARCHAR2(50),
    availabilityStatus VARCHAR2(20),
    year NUMBER,
    vehicle_make VARCHAR2(50),
    vehicle_model VARCHAR2(50)
);
/

-- Create ReservationList as TABLE of ReservationType
CREATE TYPE ReservationList AS TABLE OF ReservationType;
/

-- Create Reservation table
CREATE TABLE Reservation (
    reservationID NUMBER PRIMARY KEY,
    reservationDate DATE NOT NULL,
    customerID NUMBER,
    vehicleID NUMBER,
    rentalStartDate DATE NOT NULL,
    rentalEndDate DATE NOT NULL,
    totalAmount NUMBER(10, 2) CHECK (totalAmount >= 0),
    CONSTRAINT fk_reservation_customer FOREIGN KEY (customerID) REFERENCES Customer (customerID),
    CONSTRAINT fk_reservation_vehicle FOREIGN KEY (vehicleID) REFERENCES Vehicle (vehicleID),
    CONSTRAINT chk_rental_dates CHECK (rentalEndDate > rentalStartDate)
);

-- Create Payment table
CREATE TABLE Payment (
    paymentID NUMBER PRIMARY KEY,
    reservationID NUMBER,
    paymentDate DATE NOT NULL,
    amount NUMBER(10, 2) NOT NULL CHECK (amount >= 0),
    paymentType VARCHAR2(20) CHECK (paymentType IN ('Cash', 'Credit Card', 'Debit Card', 'Online Payment')),
    CONSTRAINT fk_payment_reservation FOREIGN KEY (reservationID) REFERENCES Reservation (reservationID)
);

-- Trigger to set default availability status in Vehicle table
CREATE OR REPLACE TRIGGER trg_default_availability_status
BEFORE INSERT ON Vehicle
FOR EACH ROW
BEGIN
    IF :NEW.availabilityStatus IS NULL THEN
        :NEW.availabilityStatus := 'Available';
    END IF;
END;
/

-- Trigger to update vehicle availability status after reservation end date update
CREATE OR REPLACE TRIGGER trg_reservation_end
AFTER UPDATE OF rentalEndDate ON Reservation
FOR EACH ROW
WHEN (NEW.rentalEndDate < SYSDATE)
BEGIN
    UPDATE Vehicle
    SET availabilityStatus = 'Available'
    WHERE vehicleID = :NEW.vehicleID;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20001, 'Failed to update vehicle availability status.');
END;
/

-- Procedure to cancel a reservation
CREATE OR REPLACE PROCEDURE CancelReservation (
    p_reservationID IN NUMBER
)
IS
BEGIN
    DELETE FROM Reservation WHERE reservationID = p_reservationID;

    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20004, 'No reservation found with the provided ID.');
    ELSE
        COMMIT;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END CancelReservation;
/ 

-- Procedure to insert a payment
CREATE OR REPLACE PROCEDURE InsertPayment (
    p_reservationID IN NUMBER,
    p_paymentDate IN DATE,
    p_amount IN NUMBER,
    p_paymentType IN VARCHAR2
)
IS
BEGIN
    INSERT INTO Payment (reservationID, paymentDate, amount, paymentType)
    VALUES (p_reservationID, p_paymentDate, p_amount, p_paymentType);

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END InsertPayment;
/ 
-- Insert categories into the Category table
INSERT INTO Category (categoryID, categoryName) VALUES (1, 'Economy');
INSERT INTO Category (categoryID, categoryName) VALUES (2, 'VIP');
INSERT INTO Category (categoryID, categoryName) VALUES (3, 'VVIP');

-- Insert customers into the Customer table
INSERT INTO Customer (customerID, name, email, address, phone, driverLicenseNumber)
VALUES (1, 'John Doe', 'john@example.com', '123 Main St, Anytown', '555-1234', 'DL123456');
INSERT INTO Customer (customerID, name, email, address, phone, driverLicenseNumber)
VALUES (2, 'Jane Smith', 'jane@example.com', '456 Elm St, Othertown', '555-5678', 'DL654321');
INSERT INTO Customer (customerID, name, email, address, phone, driverLicenseNumber)
VALUES (3, 'Bob Johnson', 'bob@example.com', '789 Oak St, Anycity', '555-9876', 'DL987654');
INSERT INTO Customer (customerID, name, email, address, phone, driverLicenseNumber)
VALUES (4, 'Alice Brown', 'alice@example.com', '321 Pine St, Anothercity', '555-4321', 'DL456789');
INSERT INTO Customer (customerID, name, email, address, phone, driverLicenseNumber)
VALUES (5, 'Charlie Green', 'charlie@example.com', '654 Cedar St, Yetanothercity', '555-8765', 'DL789456');

-- Insert vehicles into the Vehicle table
INSERT INTO Vehicle (vehicleID, registrationNumber, availabilityStatus, year, MAKE, MODEL)
VALUES (1, 'ABC123', 'Available', 2022, 'Toyota', 'Camry');
INSERT INTO Vehicle (vehicleID, registrationNumber, availabilityStatus, year, MAKE, MODEL)
VALUES (2, 'DEF456', 'Unavailable', 2021, 'Honda', 'Accord');
INSERT INTO Vehicle (vehicleID, registrationNumber, availabilityStatus, year, MAKE, MODEL)
VALUES (3, 'GHI789', 'Available', 2020, 'Ford', 'Fusion');
INSERT INTO Vehicle (vehicleID, registrationNumber, availabilityStatus, year, MAKE, MODEL)
VALUES (4, 'JKL012', 'Available', 2023, 'Chevrolet', 'Malibu');
INSERT INTO Vehicle (vehicleID, registrationNumber, availabilityStatus, year, MAKE, MODEL)
VALUES (5, 'MNO345', 'Unavailable', 2019, 'Nissan', 'Altima');

-- Insert cars into the Car table
INSERT INTO Car (vehicleID, categoryID) VALUES (1, 1);
INSERT INTO Car (vehicleID, categoryID) VALUES (2, 2);
INSERT INTO Car (vehicleID, categoryID) VALUES (3, 1);
INSERT INTO Car (vehicleID, categoryID) VALUES (4, 3);
INSERT INTO Car (vehicleID, categoryID) VALUES (5, 2);

-- Insert new vehicles and corresponding bus records
INSERT ALL
    INTO Vehicle (vehicleID, make, model, year, registrationNumber, availabilityStatus)
    VALUES (6, 'Toyota', 'Coaster', 2024, 'XYZ123', 'Available')
    INTO Vehicle (vehicleID, make, model, year, registrationNumber, availabilityStatus)
    VALUES (7, 'Ford', 'Transit', 2023, 'ABC456', 'Unavailable')
    INTO Vehicle (vehicleID, make, model, year, registrationNumber, availabilityStatus)
    VALUES (8, 'Mercedes-Benz', 'Sprinter', 2023, 'DEF789', 'Unavailable')
    INTO Vehicle (vehicleID, make, model, year, registrationNumber, availabilityStatus)
    VALUES (9, 'Volvo', 'VHD', 2022, 'GHI012', 'Available')
    INTO Vehicle (vehicleID, make, model, year, registrationNumber, availabilityStatus)
    VALUES (10, 'Scania', 'Touring', 2022, 'JKL345', 'Unavailable')
SELECT 1 FROM DUAL;
INSERT ALL
    INTO Bus (vehicleID, seatingCapacity, busType, categoryID)
    VALUES (6, 50, 'Coach', 3)
    INTO Bus (vehicleID, seatingCapacity, busType, categoryID)
    VALUES (7, 30, 'Shuttle', 1)
    INTO Bus (vehicleID, seatingCapacity, busType, categoryID)
    VALUES (8, 40, 'Touring', 2)
    INTO Bus (vehicleID, seatingCapacity, busType, categoryID)
    VALUES (9, 60, 'Charter', 1)
    INTO Bus (vehicleID, seatingCapacity, busType, categoryID)
    VALUES (10, 70, 'Luxury', 3)
SELECT 1 FROM DUAL;


Query to list customer reservations
SELECT 
    c.customerID,
    c.name AS customer_name,
    c.email,
    c.address,
    c.phone,
    c.driverLicenseNumber,
    LISTAGG(
        'Reservation ID: ' || TO_CHAR(r.reservationID) || ', ' ||
        'Reservation Date: ' || TO_CHAR(r.reservationDate, 'YYYY-MM-DD') || ', ' ||
        'Rental Start Date: ' || TO_CHAR(r.rentalStartDate, 'YYYY-MM-DD') || ', ' ||
        'Rental End Date: ' || TO_CHAR(r.rentalEndDate, 'YYYY-MM-DD') || ', ' ||
        'Total Amount: ' || TO_CHAR(r.totalAmount) || ', ' ||
        'Vehicle ID: ' || TO_CHAR(v.vehicleID) || ', ' ||
        'Registration Number: ' || v.registrationNumber || ', ' ||
        'Availability Status: ' || v.availabilityStatus || ', ' ||
        'Year: ' || TO_CHAR(v.year) || ', ' ||
        'Vehicle Make: ' || v.make || ', ' ||
        'Vehicle Model: ' || v.model,
        '; '
    ) WITHIN GROUP (ORDER BY r.reservationID) AS reservations
FROM 
    Customer c
LEFT JOIN 
    Reservation r ON c.customerID = r.customerID
LEFT JOIN 
    Vehicle v ON r.vehicleID = v.vehicleID
GROUP BY 
    c.customerID, c.name, c.email, c.address, c.phone, c.driverLicenseNumber;

-- Query to retrieve reservations with end dates after the current date
SELECT *
FROM Reservation
WHERE rentalEndDate >= SYSDATE;

-- Query to retrieve total payments grouped by vehicle make, customer name, and payment type
SELECT 
    CASE 
        WHEN v.MAKE IS NULL THEN 'Total' 
        ELSE v.MAKE 
    END AS "Vehicle Make", 
    CASE 
        WHEN c.name IS NULL THEN 'Total' 
        ELSE c.name 
    END AS "Customer Name", 
    CASE 
        WHEN pm.paymentType IS NULL THEN 'Total' 
        ELSE pm.paymentType 
    END AS "Payment Type", 
    SUM(pm.amount) AS "Total Payment" 
FROM 
    Payment pm 
LEFT JOIN 
    Reservation r ON pm.reservationID = r.reservationID 
LEFT JOIN 
    Customer c ON r.customerID = c.customerID 
LEFT JOIN 
    Vehicle v ON r.vehicleID = v.vehicleID 
GROUP BY 
    ROLLUP (v.MAKE, c.name, pm.paymentType) 
ORDER BY 
    "Vehicle Make", "Customer Name", "Payment Type";


SELECT 
    r.reservationID,
    r.rentalStartDate,
    r.rentalEndDate,
    c.name AS customer_name,
    v.registrationNumber,
    v.MAKE,
    v.MODEL,
    p.amount AS payment_amount
FROM 
    Reservation r
-- Left join with Customer table
LEFT JOIN 
    Customer c ON r.customerID = c.customerID
-- Right join with Vehicle table
RIGHT JOIN 
    Vehicle v ON r.vehicleID = v.vehicleID
-- Full outer join with Payment table
FULL OUTER JOIN 
    Payment p ON r.reservationID = p.reservationID
WHERE 
    v.availabilityStatus = 'Available'
ORDER BY 
    r.reservationID;


Select all available vehicles
SELECT 
    vehicleID,
    registrationNumber,
    MAKE,
    MODEL,
    'Available' AS availabilityStatus
FROM 
    Vehicle
WHERE 
    availabilityStatus = 'Available'

UNION

-- Select all reservations with their associated vehicle details
SELECT 
    r.vehicleID,
    v.registrationNumber,
    v.MAKE,
    v.MODEL,
    'Unavailable' AS availabilityStatus
FROM 
    Reservation r
INNER JOIN 
    Vehicle v ON r.vehicleID = v.vehicleID
ORDER BY 
    availabilityStatus;


