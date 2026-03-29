#[allow(dead_code)]
#[derive(Debug, Clone, PartialEq)]
pub enum AccountType {
    GuardianOrParent,
    Student,
}

#[allow(dead_code)]
#[derive(Debug, Clone, PartialEq)]
pub enum KycStatus {
    None,
    Pending,
    Verified,
    Failed,
}

#[allow(dead_code)]
#[derive(Debug, Clone, PartialEq)]
pub enum PlanType {
    Daily,
    Weekly,
    Monthly,
}

#[allow(dead_code)]
#[derive(Debug, Clone, PartialEq)]
pub enum PaymentMethod {
    CreditCard,
    BankTransfer,
    MtnMomo,
    OrangeMoney,
}

#[allow(dead_code)]
#[derive(Debug, Clone, PartialEq)]
pub enum PaymentStatus {
    Pending,
    Confirmed,
    Failed,
}
