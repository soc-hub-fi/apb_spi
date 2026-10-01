package sd_reg_pkg;

    // OCR (operation conditions register)
    typedef struct packed{
        // Card power up status bit, Set to low if the card has not finished the power up routine.
        bit busy; 
        // CCS Card capacity status, set only when power up status bit is set i.e. busy bit is 1. CCS 0 indicates that the card is SDSC. 1 indicates that the card is SDHC or SDXC
        bit capacity_status;
        bit uhs_II_status;
        // Switch to 1.8 V. Only supported by UHS-I type card.
        logic [3:0] low_voltage_accept; 
        // from MSB every bit indicates 3.5-3.6, 3.4-3.5 Voltage range etc.
        logic [8:0] voltage_range; 
        logic [6:0] reserved_1; // don't care about these values
        bit reserved_low_volt_rng;
        logic [6:0] reserved_2; // don't care about these values
    } ocr_t; 

    // CID (Crad identification register)
    typedef struct packed {
        logic [7:0] manufacturer_id;
        logic [15:0] application_id;
        logic [39:0] product_name;
        logic [7:0] product_revision;
        logic [31:0] serial_number;
        logic [3:0] reserved;
        logic [11:0] manufacturing_date;
        logic [6:0] crc;
        bit unused; //always 1
    } cid;

    // CSD (Card specific data register)
    /* typedef struct packed {        
    }csd; */

endpackage