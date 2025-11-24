import XCTest
@testable import PerFolio

final class TransakServiceTests: XCTestCase {
    
    // MARK: - Properties
    
    var sut: TransakService!
    var testEnvironment: EnvironmentConfiguration!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        
        // Create test environment with API key
        testEnvironment = EnvironmentConfiguration(
            environment: .development,
            apiBaseURL: URL(string: "https://test.perfolio.ai")!,
            privyAppID: "test-privy-id",
            privyAppClientID: "test-privy-client-id",
            privyAppSecret: "",
            deepLinkScheme: "perfolio-test",
            privyJWKSURL: URL(string: "https://test.privy.io")!,
            defaultOAuthProvider: "email",
            featureFlags: [],
            enablePrivySponsoredRPC: false,
            networkHeaders: [:],
            transakAPIKey: "test-transak-api-key"
        )
        
        // Store test wallet address
        UserDefaults.standard.set("0x8E0614AA1C09A9A48f1d0A09b63F0Ae8aB8a8a8a", forKey: "userWalletAddress")
        
        sut = TransakService(environment: testEnvironment)
    }
    
    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "userWalletAddress")
        sut = nil
        testEnvironment = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInit_WithAPIKey_Succeeds() {
        // Then
        XCTAssertNotNil(sut)
    }
    
    func testInit_WithoutAPIKey_Succeeds() {
        // Given
        let envWithoutKey = EnvironmentConfiguration(
            environment: .development,
            apiBaseURL: URL(string: "https://test.perfolio.ai")!,
            privyAppID: "test",
            privyAppClientID: "test",
            privyAppSecret: "",
            deepLinkScheme: "perfolio-test",
            privyJWKSURL: URL(string: "https://test.privy.io")!,
            defaultOAuthProvider: "email",
            featureFlags: [],
            enablePrivySponsoredRPC: false,
            networkHeaders: [:],
            transakAPIKey: ""  // Empty API key
        )
        
        // When
        let service = TransakService(environment: envWithoutKey)
        
        // Then
        XCTAssertNotNil(service)  // Should init but will throw error on use
    }
    
    // MARK: - buildWithdrawURL(request:) Tests
    
    func testBuildWithdrawURL_ValidRequest_ReturnsURL() throws {
        // Given
        let request = TransakService.WithdrawRequest(
            cryptoAmount: "50",
            cryptoCurrency: "USDC",
            fiatCurrency: "INR",
            walletAddress: "0x8E0614AA1C09A9A48f1d0A09b63F0Ae8aB8a8a8a",
            network: "ethereum"
        )
        
        // When
        let url = try sut.buildWithdrawURL(request: request)
        
        // Then
        XCTAssertNotNil(url)
        XCTAssertTrue(url.absoluteString.contains("global.transak.com"))
    }
    
    func testBuildWithdrawURL_ContainsAPIKey() throws {
        // Given
        let request = TransakService.WithdrawRequest(
            cryptoAmount: "50",
            walletAddress: "0xTest"
        )
        
        // When
        let url = try sut.buildWithdrawURL(request: request)
        
        // Then
        XCTAssertTrue(url.absoluteString.contains("apiKey=test-transak-api-key"))
    }
    
    func testBuildWithdrawURL_ContainsWalletAddress() throws {
        // Given
        let walletAddress = "0x8E0614AA1C09A9A48f1d0A09b63F0Ae8aB8a8a8a"
        let request = TransakService.WithdrawRequest(
            cryptoAmount: "50",
            walletAddress: walletAddress
        )
        
        // When
        let url = try sut.buildWithdrawURL(request: request)
        
        // Then
        XCTAssertTrue(url.absoluteString.contains("walletAddress=\(walletAddress)"))
    }
    
    func testBuildWithdrawURL_ContainsCryptoAmount() throws {
        // Given
        let request = TransakService.WithdrawRequest(
            cryptoAmount: "123.45",
            walletAddress: "0xTest"
        )
        
        // When
        let url = try sut.buildWithdrawURL(request: request)
        
        // Then
        XCTAssertTrue(url.absoluteString.contains("cryptoAmount=123.45"))
    }
    
    func testBuildWithdrawURL_ContainsCryptoCurrency() throws {
        // Given
        let request = TransakService.WithdrawRequest(
            cryptoAmount: "50",
            cryptoCurrency: "USDC",
            walletAddress: "0xTest"
        )
        
        // When
        let url = try sut.buildWithdrawURL(request: request)
        
        // Then
        XCTAssertTrue(url.absoluteString.contains("cryptoCurrencyCode=USDC"))
    }
    
    func testBuildWithdrawURL_ContainsFiatCurrency() throws {
        // Given
        let request = TransakService.WithdrawRequest(
            cryptoAmount: "50",
            fiatCurrency: "INR",
            walletAddress: "0xTest"
        )
        
        // When
        let url = try sut.buildWithdrawURL(request: request)
        
        // Then
        XCTAssertTrue(url.absoluteString.contains("fiatCurrency=INR"))
    }
    
    func testBuildWithdrawURL_ContainsProductsAvailed() throws {
        // Given
        let request = TransakService.WithdrawRequest(
            cryptoAmount: "50",
            walletAddress: "0xTest"
        )
        
        // When
        let url = try sut.buildWithdrawURL(request: request)
        
        // Then
        XCTAssertTrue(url.absoluteString.contains("productsAvailed=SELL"))
    }
    
    func testBuildWithdrawURL_ContainsNetwork() throws {
        // Given
        let request = TransakService.WithdrawRequest(
            cryptoAmount: "50",
            walletAddress: "0xTest",
            network: "ethereum"
        )
        
        // When
        let url = try sut.buildWithdrawURL(request: request)
        
        // Then
        XCTAssertTrue(url.absoluteString.contains("network=ethereum"))
    }
    
    func testBuildWithdrawURL_ContainsDeepLinkRedirect() throws {
        // Given
        let request = TransakService.WithdrawRequest(
            cryptoAmount: "50",
            walletAddress: "0xTest"
        )
        
        // When
        let url = try sut.buildWithdrawURL(request: request)
        
        // Then
        XCTAssertTrue(url.absoluteString.contains("redirectURL=perfolio-test://transak-complete"))
    }
    
    func testBuildWithdrawURL_ProductionEnvironment_UsesProductionMode() throws {
        // Given
        let prodEnv = EnvironmentConfiguration(
            environment: .production,
            apiBaseURL: URL(string: "https://perfolio.ai")!,
            privyAppID: "test",
            privyAppClientID: "test",
            privyAppSecret: "",
            deepLinkScheme: "perfolio",
            privyJWKSURL: URL(string: "https://test.privy.io")!,
            defaultOAuthProvider: "email",
            featureFlags: [],
            enablePrivySponsoredRPC: false,
            networkHeaders: [:],
            transakAPIKey: "prod-key"
        )
        let prodService = TransakService(environment: prodEnv)
        let request = TransakService.WithdrawRequest(
            cryptoAmount: "50",
            walletAddress: "0xTest"
        )
        
        // When
        let url = try prodService.buildWithdrawURL(request: request)
        
        // Then
        XCTAssertTrue(url.absoluteString.contains("environment=PRODUCTION"))
    }
    
    func testBuildWithdrawURL_DevelopmentEnvironment_UsesStagingMode() throws {
        // Given
        let request = TransakService.WithdrawRequest(
            cryptoAmount: "50",
            walletAddress: "0xTest"
        )
        
        // When
        let url = try sut.buildWithdrawURL(request: request)
        
        // Then
        XCTAssertTrue(url.absoluteString.contains("environment=STAGING"))
    }
    
    // MARK: - Error Tests
    
    func testBuildWithdrawURL_MissingAPIKey_ThrowsError() {
        // Given
        let envWithoutKey = EnvironmentConfiguration(
            environment: .development,
            apiBaseURL: URL(string: "https://test.perfolio.ai")!,
            privyAppID: "test",
            privyAppClientID: "test",
            privyAppSecret: "",
            deepLinkScheme: "perfolio-test",
            privyJWKSURL: URL(string: "https://test.privy.io")!,
            defaultOAuthProvider: "email",
            featureFlags: [],
            enablePrivySponsoredRPC: false,
            networkHeaders: [:],
            transakAPIKey: ""  // Empty API key
        )
        let service = TransakService(environment: envWithoutKey)
        let request = TransakService.WithdrawRequest(
            cryptoAmount: "50",
            walletAddress: "0xTest"
        )
        
        // When/Then
        XCTAssertThrowsError(try service.buildWithdrawURL(request: request)) { error in
            XCTAssertTrue(error is TransakService.TransakError)
            if let transakError = error as? TransakService.TransakError,
               case .missingAPIKey = transakError {
                // Success
            } else {
                XCTFail("Wrong error type")
            }
        }
    }
    
    func testBuildWithdrawURL_ZeroAmount_ThrowsError() {
        // Given
        let request = TransakService.WithdrawRequest(
            cryptoAmount: "0",
            walletAddress: "0xTest"
        )
        
        // When/Then
        XCTAssertThrowsError(try sut.buildWithdrawURL(request: request)) { error in
            if let transakError = error as? TransakService.TransakError,
               case .invalidAmount = transakError {
                // Success
            } else {
                XCTFail("Wrong error type")
            }
        }
    }
    
    func testBuildWithdrawURL_NegativeAmount_ThrowsError() {
        // Given
        let request = TransakService.WithdrawRequest(
            cryptoAmount: "-10",
            walletAddress: "0xTest"
        )
        
        // When/Then
        XCTAssertThrowsError(try sut.buildWithdrawURL(request: request)) { error in
            if let transakError = error as? TransakService.TransakError,
               case .invalidAmount = transakError {
                // Success
            } else {
                XCTFail("Wrong error type")
            }
        }
    }
    
    func testBuildWithdrawURL_InvalidAmount_ThrowsError() {
        // Given
        let request = TransakService.WithdrawRequest(
            cryptoAmount: "abc",
            walletAddress: "0xTest"
        )
        
        // When/Then
        XCTAssertThrowsError(try sut.buildWithdrawURL(request: request)) { error in
            if let transakError = error as? TransakService.TransakError,
               case .invalidAmount = transakError {
                // Success
            } else {
                XCTFail("Wrong error type")
            }
        }
    }
    
    func testBuildWithdrawURL_EmptyWalletAddress_ThrowsError() {
        // Given
        let request = TransakService.WithdrawRequest(
            cryptoAmount: "50",
            walletAddress: ""
        )
        
        // When/Then
        XCTAssertThrowsError(try sut.buildWithdrawURL(request: request)) { error in
            if let transakError = error as? TransakService.TransakError,
               case .missingWalletAddress = transakError {
                // Success
            } else {
                XCTFail("Wrong error type")
            }
        }
    }
    
    // MARK: - Convenience Method Tests
    
    func testBuildWithdrawURL_ConvenienceMethod_UsesUserDefaults() throws {
        // When
        let url = try sut.buildWithdrawURL(
            cryptoAmount: "50",
            cryptoCurrency: "USDC",
            fiatCurrency: "INR"
        )
        
        // Then
        XCTAssertTrue(url.absoluteString.contains("0x8E0614AA1C09A9A48f1d0A09b63F0Ae8aB8a8a8a"))
    }
    
    func testBuildWithdrawURL_ConvenienceMethod_NoWalletInUserDefaults_ThrowsError() {
        // Given
        UserDefaults.standard.removeObject(forKey: "userWalletAddress")
        
        // When/Then
        XCTAssertThrowsError(try sut.buildWithdrawURL(cryptoAmount: "50")) { error in
            if let transakError = error as? TransakService.TransakError,
               case .missingWalletAddress = transakError {
                // Success
            } else {
                XCTFail("Wrong error type")
            }
        }
    }
    
    // MARK: - parseRedirectURL Tests
    
    func testParseRedirectURL_CompletedStatus_ReturnsCompleted() {
        // Given
        let urlString = "perfolio-test://transak-complete?transak_status=COMPLETED&transak_order_id=12345"
        let url = URL(string: urlString)!
        
        // When
        let status = sut.parseRedirectURL(url)
        
        // Then
        if case .completed(let orderId) = status {
            XCTAssertEqual(orderId, "12345")
        } else {
            XCTFail("Expected completed status")
        }
    }
    
    func testParseRedirectURL_FailedStatus_ReturnsFailed() {
        // Given
        let urlString = "perfolio-test://transak-complete?transak_status=FAILED&transak_order_id=67890"
        let url = URL(string: urlString)!
        
        // When
        let status = sut.parseRedirectURL(url)
        
        // Then
        if case .failed(let orderId) = status {
            XCTAssertEqual(orderId, "67890")
        } else {
            XCTFail("Expected failed status")
        }
    }
    
    func testParseRedirectURL_CancelledStatus_ReturnsCancelled() {
        // Given
        let urlString = "perfolio-test://transak-complete?transak_status=CANCELLED&transak_order_id=99999"
        let url = URL(string: urlString)!
        
        // When
        let status = sut.parseRedirectURL(url)
        
        // Then
        if case .cancelled(let orderId) = status {
            XCTAssertEqual(orderId, "99999")
        } else {
            XCTFail("Expected cancelled status")
        }
    }
    
    func testParseRedirectURL_UnknownStatus_ReturnsUnknown() {
        // Given
        let urlString = "perfolio-test://transak-complete?transak_status=PENDING"
        let url = URL(string: urlString)!
        
        // When
        let status = sut.parseRedirectURL(url)
        
        // Then
        if case .unknown = status {
            // Success
        } else {
            XCTFail("Expected unknown status")
        }
    }
    
    func testParseRedirectURL_NoStatus_ReturnsUnknown() {
        // Given
        let urlString = "perfolio-test://transak-complete"
        let url = URL(string: urlString)!
        
        // When
        let status = sut.parseRedirectURL(url)
        
        // Then
        if case .unknown = status {
            // Success
        } else {
            XCTFail("Expected unknown status")
        }
    }
    
    func testParseRedirectURL_NoOrderId_ReturnsNilOrderId() {
        // Given
        let urlString = "perfolio-test://transak-complete?transak_status=COMPLETED"
        let url = URL(string: urlString)!
        
        // When
        let status = sut.parseRedirectURL(url)
        
        // Then
        if case .completed(let orderId) = status {
            XCTAssertNil(orderId)
        } else {
            XCTFail("Expected completed status with nil order ID")
        }
    }
    
    func testParseRedirectURL_CaseInsensitive_HandlesLowercase() {
        // Given
        let urlString = "perfolio-test://transak-complete?transak_status=completed&transak_order_id=12345"
        let url = URL(string: urlString)!
        
        // When
        let status = sut.parseRedirectURL(url)
        
        // Then
        if case .completed(let orderId) = status {
            XCTAssertEqual(orderId, "12345")
        } else {
            XCTFail("Expected completed status")
        }
    }
}

