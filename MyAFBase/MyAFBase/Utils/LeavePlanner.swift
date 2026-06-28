import Foundation

enum LeavePlanner {
    static let defaultMaxBalanceAtPCS = 60.0
    static let fiscalYearCarryCap = 60.0
    static let defaultAccrualPerMonth = 2.5
    static let defaultMaxAccruingBalance = 60.0
    static let daysPerAccrualMonth = 30.44

    static func leaveDays(
        from leaveStartDate: Date,
        to leaveEndDate: Date,
        calendar: Calendar = .current
    ) -> Int? {
        let start = calendar.startOfDay(for: leaveStartDate)
        let end = calendar.startOfDay(for: leaveEndDate)
        guard end >= start else { return nil }
        return (calendar.dateComponents([.day], from: start, to: end).day ?? 0) + 1
    }

    static func evaluateTripCoverage(
        currentBalance: Double,
        leaveStartDate: Date,
        leaveEndDate: Date,
        accrualPerMonth: Double = defaultAccrualPerMonth,
        maxAccruingBalance: Double = defaultMaxAccruingBalance,
        from referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) -> LeaveTripCoverageResult? {
        guard currentBalance >= 0,
              accrualPerMonth >= 0,
              maxAccruingBalance > 0 else {
            return nil
        }

        let startOfToday = calendar.startOfDay(for: referenceDate)
        let startOfLeave = calendar.startOfDay(for: leaveStartDate)
        let endOfLeave = calendar.startOfDay(for: leaveEndDate)

        guard let leaveDayCount = leaveDays(from: startOfLeave, to: endOfLeave, calendar: calendar),
              leaveDayCount > 0 else {
            return LeaveTripCoverageResult(
                leaveStartDate: startOfLeave,
                leaveEndDate: endOfLeave,
                leaveDays: 0,
                daysUntilLeave: 0,
                currentBalance: currentBalance,
                projectedBalance: currentBalance,
                accruedByLeave: 0,
                surplus: currentBalance,
                isCovered: false,
                notes: ["End date must be on or after the start date."]
            )
        }

        let requestedDays = Double(leaveDayCount)
        let daysUntilLeave = calendar.dateComponents([.day], from: startOfToday, to: startOfLeave).day ?? 0

        guard daysUntilLeave >= 0 else {
            return LeaveTripCoverageResult(
                leaveStartDate: startOfLeave,
                leaveEndDate: endOfLeave,
                leaveDays: requestedDays,
                daysUntilLeave: daysUntilLeave,
                currentBalance: currentBalance,
                projectedBalance: currentBalance,
                accruedByLeave: 0,
                surplus: currentBalance - requestedDays,
                isCovered: currentBalance >= requestedDays,
                notes: ["Leave start date cannot be in the past."]
            )
        }

        let accruedByLeave = daysUntilLeave == 0 ? 0 : accruedLeave(
            from: currentBalance,
            daysUntil: daysUntilLeave,
            accrualPerMonth: accrualPerMonth,
            maxBalance: maxAccruingBalance
        )
        let projectedBalance = min(maxAccruingBalance, currentBalance + accruedByLeave)
        let surplus = projectedBalance - requestedDays
        let isCovered = surplus >= -0.05

        var notes: [String] = []

        if currentBalance >= requestedDays {
            notes.append("You already have enough leave today for this period.")
        } else if isCovered {
            notes.append(
                "Projected balance on \(formatDate(startOfLeave, calendar: calendar)) covers \(formattedDays(requestedDays))."
            )
        } else {
            notes.append(
                "Projected shortfall of \(formattedDays(abs(surplus))) when leave starts on \(formatDate(startOfLeave, calendar: calendar))."
            )
            let daysNeeded = daysUntilLeaveNeeded(
                currentBalance: currentBalance,
                requestedDays: requestedDays,
                accrualPerMonth: accrualPerMonth,
                maxBalance: maxAccruingBalance
            )
            if let daysNeeded, daysNeeded > daysUntilLeave {
                notes.append(
                    "At \(formattedRate(accrualPerMonth)), you may need roughly \(daysNeeded) more days from today before you have enough."
                )
            }
        }

        if projectedBalance >= maxAccruingBalance - 0.05 {
            notes.append("Projection assumes accrual slows near the \(Int(maxAccruingBalance))-day balance cap.")
        }

        notes.append("Uses your entered accrual rate. Confirm earnings and caps on your LES with CSS.")

        return LeaveTripCoverageResult(
            leaveStartDate: startOfLeave,
            leaveEndDate: endOfLeave,
            leaveDays: requestedDays,
            daysUntilLeave: daysUntilLeave,
            currentBalance: currentBalance,
            projectedBalance: projectedBalance,
            accruedByLeave: accruedByLeave,
            surplus: surplus,
            isCovered: isCovered,
            notes: notes
        )
    }

    /// Accrual with a simple balance cap applied over the projection window.
    private static func accruedLeave(
        from startingBalance: Double,
        daysUntil: Int,
        accrualPerMonth: Double,
        maxBalance: Double
    ) -> Double {
        guard daysUntil > 0, accrualPerMonth > 0, startingBalance < maxBalance else {
            return 0
        }

        let months = Double(daysUntil) / daysPerAccrualMonth
        let uncapped = months * accrualPerMonth
        let roomToCap = max(0, maxBalance - startingBalance)
        return min(uncapped, roomToCap)
    }

    private static func daysUntilLeaveNeeded(
        currentBalance: Double,
        requestedDays: Double,
        accrualPerMonth: Double,
        maxBalance: Double
    ) -> Int? {
        guard currentBalance < requestedDays, accrualPerMonth > 0 else { return nil }

        let deficit = requestedDays - currentBalance
        let roomToCap = max(0, maxBalance - currentBalance)
        let achievableAccrual = min(deficit, roomToCap)
        let monthsNeeded = achievableAccrual / accrualPerMonth
        return Int(ceil(monthsNeeded * daysPerAccrualMonth))
    }

    static func plan(
        currentBalance: Double,
        pcsDate: Date,
        maxBalanceAtPCS: Double = defaultMaxBalanceAtPCS,
        specialLeaveBalance: Double = 0,
        specialLeaveExpires: Date? = nil,
        from referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) -> LeavePlanResult? {
        guard currentBalance >= 0, maxBalanceAtPCS >= 0, specialLeaveBalance >= 0 else {
            return nil
        }

        let startOfToday = calendar.startOfDay(for: referenceDate)
        let startOfPCS = calendar.startOfDay(for: pcsDate)
        let daysUntilPCS = calendar.dateComponents([.day], from: startOfToday, to: startOfPCS).day ?? 0

        guard daysUntilPCS > 0 else {
            return LeavePlanResult(
                daysUntilPCS: daysUntilPCS,
                currentBalance: currentBalance,
                maxBalanceAtPCS: maxBalanceAtPCS,
                excessLeave: 0,
                specialLeaveBalance: specialLeaveBalance,
                daysPerWeekToUse: 0,
                daysPerMonthToUse: 0,
                milestones: [],
                notes: ["PCS date must be in the future to build a usage plan."]
            )
        }

        var notes: [String] = []
        let excessLeave = max(0, currentBalance - maxBalanceAtPCS)
        let weeksRemaining = max(1.0, Double(daysUntilPCS) / 7.0)
        let monthsRemaining = max(1.0, Double(daysUntilPCS) / 30.44)
        let daysPerWeek = excessLeave / weeksRemaining
        let daysPerMonth = excessLeave / monthsRemaining

        if excessLeave <= 0 {
            notes.append("Your balance is at or below the \(Int(maxBalanceAtPCS))-day PCS planning cap. No mandatory usage pace is required.")
        } else {
            notes.append("Use about \(formattedDays(daysPerMonth)) per month (or \(formattedDays(daysPerWeek)) per week) to burn \(formattedDays(excessLeave)) before PCS.")
        }

        if let fyDeadline = nextFiscalYearEnd(after: referenceDate, calendar: calendar),
           fyDeadline < startOfPCS,
           currentBalance > fiscalYearCarryCap {
            let fyExcess = currentBalance - fiscalYearCarryCap
            notes.append(
                "Fiscal year ends \(formatDate(fyDeadline, calendar: calendar)): \(formattedDays(fyExcess)) above the 60-day carryover cap should be used by then or it may be lost."
            )
        }

        if specialLeaveBalance > 0 {
            if let expiration = specialLeaveExpires {
                if expiration < startOfPCS {
                    notes.append(
                        "Use \(formattedDays(specialLeaveBalance)) special leave before it expires on \(formatDate(expiration, calendar: calendar))."
                    )
                } else {
                    notes.append("You have \(formattedDays(specialLeaveBalance)) special leave on the books — confirm expiration with your CSS.")
                }
            } else {
                notes.append("You entered \(formattedDays(specialLeaveBalance)) special leave — add an expiration date if it is use-or-lose.")
            }
        }

        notes.append("Unofficial estimate only. Confirm balances, sell-back rules, and PCS leave limits with your unit CSS.")

        let milestones = buildMilestones(
            excessLeave: excessLeave,
            daysUntilPCS: daysUntilPCS,
            referenceDate: startOfToday,
            calendar: calendar
        )

        return LeavePlanResult(
            daysUntilPCS: daysUntilPCS,
            currentBalance: currentBalance,
            maxBalanceAtPCS: maxBalanceAtPCS,
            excessLeave: excessLeave,
            specialLeaveBalance: specialLeaveBalance,
            daysPerWeekToUse: daysPerWeek,
            daysPerMonthToUse: daysPerMonth,
            milestones: milestones,
            notes: notes
        )
    }

    private static func buildMilestones(
        excessLeave: Double,
        daysUntilPCS: Int,
        referenceDate: Date,
        calendar: Calendar
    ) -> [LeaveMilestone] {
        guard excessLeave > 0 else { return [] }

        var milestones: [LeaveMilestone] = []
        let checkpointCount = min(4, max(1, daysUntilPCS / 30))
        let intervalDays = max(7, daysUntilPCS / checkpointCount)

        for index in 1...checkpointCount {
            guard let checkpointDate = calendar.date(byAdding: .day, value: intervalDays * index, to: referenceDate) else {
                continue
            }
            let progress = Double(index) / Double(checkpointCount)
            let cumulativeTarget = (excessLeave * progress).rounded()
            milestones.append(
                LeaveMilestone(
                    date: checkpointDate,
                    title: "Use \(formattedDays(cumulativeTarget)) by then",
                    detail: "\(Int((progress * 100).rounded()))% of excess leave planned"
                )
            )
        }

        return milestones
    }

    private static func nextFiscalYearEnd(after date: Date, calendar: Calendar) -> Date? {
        var components = calendar.dateComponents([.year], from: date)
        components.month = 9
        components.day = 30
        guard var candidate = calendar.date(from: components) else { return nil }

        if candidate <= date {
            components.year = (components.year ?? 0) + 1
            candidate = calendar.date(from: components) ?? candidate
        }

        return candidate
    }

    private static func formattedDays(_ value: Double) -> String {
        let rounded = (value * 10).rounded() / 10
        if rounded == rounded.rounded() {
            return "\(Int(rounded)) days"
        }
        return String(format: "%.1f days", rounded)
    }

    private static func formattedRate(_ value: Double) -> String {
        if value == value.rounded() {
            return "\(Int(value)) days/month"
        }
        return String(format: "%.1f days/month", value)
    }

    private static func formatDate(_ date: Date, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct LeaveTripCoverageResult: Equatable {
    let leaveStartDate: Date
    let leaveEndDate: Date
    let leaveDays: Double
    let daysUntilLeave: Int
    let currentBalance: Double
    let projectedBalance: Double
    let accruedByLeave: Double
    let surplus: Double
    let isCovered: Bool
    let notes: [String]

    var shortfall: Double {
        max(0, -surplus)
    }

    var spareDays: Double {
        max(0, surplus)
    }

    var isValidRange: Bool {
        leaveDays > 0
    }
}

struct LeavePlanResult: Equatable {
    let daysUntilPCS: Int
    let currentBalance: Double
    let maxBalanceAtPCS: Double
    let excessLeave: Double
    let specialLeaveBalance: Double
    let daysPerWeekToUse: Double
    let daysPerMonthToUse: Double
    let milestones: [LeaveMilestone]
    let notes: [String]

    var needsUsagePlan: Bool {
        excessLeave > 0
    }
}

struct LeaveMilestone: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let title: String
    let detail: String
}
