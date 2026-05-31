"""ReconSnap statement extraction API.

A thin service whose only job is to turn an uploaded PDF into clean text. All
transaction parsing, debit/credit reconciliation, and balance validation live
in the Flutter client (`TransactionLineParser`) so that logic stays in one
place and the backend remains stateless and easy to reason about for privacy.
"""

__version__ = "0.1.0"
