import XCTest
@testable import VimaiHitRise

final class TrainingSessionControllerTests: XCTestCase {
    func testCaloriesFormulaReturnsPositiveValueForActiveSession() {
        let calories = TrainingSessionController.caloriesForTraining(
            totalHits: 100,
            durationSeconds: 60,
            avgForceN: 700
        )

        XCTAssertGreaterThan(calories, 0)
    }
}
