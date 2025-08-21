import Foundation
import UIKit
import PDFKit

// MARK: - Export Service Protocol

protocol ExportServiceProtocol {
    func generatePDF(for session: Session, gridPoints: [GridPoint], photos: [PhotoAsset]) async throws -> URL
    func generateCSV(for session: Session, gridPoints: [GridPoint]) async throws -> URL
    func generateJSON(for session: Session, gridPoints: [GridPoint], photos: [PhotoAsset]) async throws -> URL
}

// MARK: - Export Service Implementation

class ExportService: ExportServiceProtocol {
    
    /// Generate a professional PDF report for a session
    /// - Parameters:
    ///   - session: The measurement session
    ///   - gridPoints: Array of grid points with measurements
    ///   - photos: Array of photo assets
    /// - Returns: URL to the generated PDF file
    func generatePDF(for session: Session, gridPoints: [GridPoint], photos: [PhotoAsset]) async throws -> URL {
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792)) // US Letter size
        
        let fileName = generateFileName(for: session, extension: "pdf")
        let fileURL = try getDocumentsDirectory().appendingPathComponent(fileName)
        
        let data = pdfRenderer.pdfData { context in
            context.beginPage()
            
            // Header
            drawHeader(context: context, session: session)
            
            // Statistics
            drawStatistics(context: context, gridPoints: gridPoints, session: session)
            
            // Data table
            drawDataTable(context: context, gridPoints: gridPoints, session: session)
            
            // Photo thumbnails
            drawPhotoThumbnails(context: context, photos: photos, gridPoints: gridPoints)
            
            // Footer
            drawFooter(context: context, session: session)
        }
        
        try data.write(to: fileURL)
        return fileURL
    }
    
    /// Generate CSV export for a session
    /// - Parameters:
    ///   - session: The measurement session
    ///   - gridPoints: Array of grid points with measurements
    /// - Returns: URL to the generated CSV file
    func generateCSV(for session: Session, gridPoints: [GridPoint]) async throws -> URL {
        let fileName = generateFileName(for: session, extension: "csv")
        let fileURL = try getDocumentsDirectory().appendingPathComponent(fileName)
        
        var csvContent = "Point,AI Value,AI Confidence,Final Value,LiDAR Height,Deviation,Pass/Fail\n"
        
        for point in gridPoints.sorted(by: { "\($0.rowLetter)\($0.colIndex)" < "\($1.rowLetter)\($1.colIndex)" }) {
            let pointLabel = "\(point.rowLetter)\(point.colIndex)"
            let aiValue = point.aiMeasuredDisplay ?? "N/A"
            let aiConfidence = point.aiConfidence.map { String(format: "%.2f", $0) } ?? "N/A"
            let finalValue = point.measuredUserDisplay ?? "N/A"
            let lidarHeight = point.lidarHeight.map { formatMeasurement($0, units: session.units) } ?? "N/A"
            let deviation = point.deviationFromAvg.map { formatMeasurement($0, units: session.units) } ?? "N/A"
            let passFail = point.passFail.map { $0 ? "PASS" : "FAIL" } ?? "N/A"
            
            csvContent += "\(pointLabel),\(aiValue),\(aiConfidence),\(finalValue),\(lidarHeight),\(deviation),\(passFail)\n"
        }
        
        try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
    
    /// Generate JSON export for a session
    /// - Parameters:
    ///   - session: The measurement session
    ///   - gridPoints: Array of grid points with measurements
    ///   - photos: Array of photo assets
    /// - Returns: URL to the generated JSON file
    func generateJSON(for session: Session, gridPoints: [GridPoint], photos: [PhotoAsset]) async throws -> URL {
        let fileName = generateFileName(for: session, extension: "json")
        let fileURL = try getDocumentsDirectory().appendingPathComponent(fileName)
        
        let exportData = SessionExportData(
            session: session,
            gridPoints: gridPoints,
            photos: photos,
            statistics: ToleranceEngine.calculateToleranceStats(points: gridPoints, tolerance: session.tolerance, units: session.units)
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        
        let jsonData = try encoder.encode(exportData)
        try jsonData.write(to: fileURL)
        
        return fileURL
    }
    
    // MARK: - Private Methods
    
    private func drawHeader(context: UIGraphicsPDFRendererContext, session: Session) {
        let pageRect = context.pdfContextBounds
        
        // Title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 24),
            .foregroundColor: UIColor.black
        ]
        
        let title = "Floor Level Verification Report"
        let titleRect = CGRect(x: 50, y: 50, width: pageRect.width - 100, height: 30)
        title.draw(in: titleRect, withAttributes: titleAttributes)
        
        // Session info
        let infoAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.darkGray
        ]
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        let sessionInfo = [
            "Session ID: \(session.id.uuidString)",
            "Date: \(dateFormatter.string(from: session.startedAt))",
            "Units: \(session.units.displayName)",
            "Tolerance: \(formatMeasurement(session.tolerance, units: session.units))",
            "Grid: \(session.rows) × \(session.cols)",
            "Rectangle: \(formatMeasurement(Double(session.rectWidth), units: session.units)) × \(formatMeasurement(Double(session.rectLength), units: session.units))"
        ]
        
        var yOffset: CGFloat = 100
        for info in sessionInfo {
            let infoRect = CGRect(x: 50, y: yOffset, width: pageRect.width - 100, height: 20)
            info.draw(in: infoRect, withAttributes: infoAttributes)
            yOffset += 20
        }
    }
    
    private func drawStatistics(context: UIGraphicsPDFRendererContext, gridPoints: [GridPoint], session: Session) {
        let pageRect = context.pdfContextBounds
        let stats = ToleranceEngine.calculateToleranceStats(points: gridPoints, tolerance: session.tolerance, units: session.units)
        
        // Statistics section title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 16),
            .foregroundColor: UIColor.black
        ]
        
        let title = "Statistical Summary"
        let titleRect = CGRect(x: 50, y: 220, width: pageRect.width - 100, height: 20)
        title.draw(in: titleRect, withAttributes: titleAttributes)
        
        // Statistics table
        let statAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.black
        ]
        
        let statistics = [
            ("Average", formatMeasurement(stats.average, units: session.units)),
            ("Minimum", formatMeasurement(stats.minimum, units: session.units)),
            ("Maximum", formatMeasurement(stats.maximum, units: session.units)),
            ("Range", formatMeasurement(stats.range, units: session.units)),
            ("Max Pairwise Delta", formatMeasurement(stats.maxPairwiseDelta, units: session.units)),
            ("Exceedances", "\(stats.exceedanceCount) of \(stats.totalPoints)"),
            ("Pass Rate", "\(Int((1.0 - Double(stats.exceedanceCount) / Double(stats.totalPoints)) * 100))%")
        ]
        
        var yOffset: CGFloat = 250
        for (label, value) in statistics {
            let labelRect = CGRect(x: 50, y: yOffset, width: 150, height: 20)
            let valueRect = CGRect(x: 200, y: yOffset, width: 100, height: 20)
            
            label.draw(in: labelRect, withAttributes: statAttributes)
            value.draw(in: valueRect, withAttributes: statAttributes)
            
            yOffset += 20
        }
    }
    
    private func drawDataTable(context: UIGraphicsPDFRendererContext, gridPoints: [GridPoint], session: Session) {
        let pageRect = context.pdfContextBounds
        
        // Table title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 16),
            .foregroundColor: UIColor.black
        ]
        
        let title = "Measurement Data"
        let titleRect = CGRect(x: 50, y: 400, width: pageRect.width - 100, height: 20)
        title.draw(in: titleRect, withAttributes: titleAttributes)
        
        // Table headers
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 10),
            .foregroundColor: UIColor.white
        ]
        
        let headerBackground = UIColor.darkGray
        headerBackground.setFill()
        
        let headers = ["Point", "AI Value", "Conf", "Final", "LiDAR", "Dev", "P/F"]
        let columnWidths: [CGFloat] = [40, 60, 30, 60, 50, 50, 30]
        let startX: CGFloat = 50
        let startY: CGFloat = 430
        let rowHeight: CGFloat = 20
        
        // Draw header background
        let headerRect = CGRect(x: startX, y: startY, width: columnWidths.reduce(0, +), height: rowHeight)
        context.fill(headerRect)
        
        // Draw header text
        var xOffset: CGFloat = startX
        for (index, header) in headers.enumerated() {
            let headerRect = CGRect(x: xOffset, y: startY, width: columnWidths[index], height: rowHeight)
            header.draw(in: headerRect, withAttributes: headerAttributes)
            xOffset += columnWidths[index]
        }
        
        // Table data
        let dataAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9),
            .foregroundColor: UIColor.black
        ]
        
        let sortedPoints = gridPoints.sorted(by: { "\($0.rowLetter)\($0.colIndex)" < "\($1.rowLetter)\($1.colIndex)" })
        
        for (rowIndex, point) in sortedPoints.enumerated() {
            let rowY = startY + rowHeight + CGFloat(rowIndex) * rowHeight
            
            // Alternate row colors
            if rowIndex % 2 == 0 {
                UIColor.lightGray.withAlphaComponent(0.3).setFill()
                let rowRect = CGRect(x: startX, y: rowY, width: columnWidths.reduce(0, +), height: rowHeight)
                context.fill(rowRect)
            }
            
            let data = [
                "\(point.rowLetter)\(point.colIndex)",
                point.aiMeasuredDisplay ?? "N/A",
                point.aiConfidence.map { String(format: "%.1f", $0) } ?? "N/A",
                point.measuredUserDisplay ?? "N/A",
                point.lidarHeight.map { formatMeasurement($0, units: session.units) } ?? "N/A",
                point.deviationFromAvg.map { formatMeasurement($0, units: session.units) } ?? "N/A",
                point.passFail.map { $0 ? "P" : "F" } ?? "N/A"
            ]
            
            xOffset = startX
            for (index, value) in data.enumerated() {
                let cellRect = CGRect(x: xOffset, y: rowY, width: columnWidths[index], height: rowHeight)
                value.draw(in: cellRect, withAttributes: dataAttributes)
                xOffset += columnWidths[index]
            }
        }
    }
    
    private func drawPhotoThumbnails(context: UIGraphicsPDFRendererContext, photos: [PhotoAsset], gridPoints: [GridPoint]) {
        let pageRect = context.pdfContextBounds
        
        // Photos section title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 16),
            .foregroundColor: UIColor.black
        ]
        
        let title = "Measurement Photos"
        let titleRect = CGRect(x: 50, y: 650, width: pageRect.width - 100, height: 20)
        title.draw(in: titleRect, withAttributes: titleAttributes)
        
        // Draw photo thumbnails
        let thumbnailSize: CGFloat = 80
        let photosPerRow = 6
        let startX: CGFloat = 50
        let startY: CGFloat = 680
        
        for (index, photo) in photos.enumerated() {
            let row = index / photosPerRow
            let col = index % photosPerRow
            
            let x = startX + CGFloat(col) * (thumbnailSize + 10)
            let y = startY + CGFloat(row) * (thumbnailSize + 30)
            
            // Load and draw photo
            if let image = UIImage(contentsOfFile: photo.fileURL.path) {
                let thumbnailRect = CGRect(x: x, y: y, width: thumbnailSize, height: thumbnailSize)
                image.draw(in: thumbnailRect)
                
                // Photo label
                let labelAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 8),
                    .foregroundColor: UIColor.darkGray
                ]
                
                if let gridPoint = gridPoints.first(where: { $0.id == photo.gridPointId }) {
                    let label = "\(gridPoint.rowLetter)\(gridPoint.colIndex)"
                    let labelRect = CGRect(x: x, y: y + thumbnailSize + 5, width: thumbnailSize, height: 15)
                    label.draw(in: labelRect, withAttributes: labelAttributes)
                }
            }
        }
    }
    
    private func drawFooter(context: UIGraphicsPDFRendererContext, session: Session) {
        let pageRect = context.pdfContextBounds
        
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.darkGray
        ]
        
        let footer = [
            "Generated by LevelMap v1.0",
            "Device: \(session.deviceInfo.model)",
            "LiDAR: \(session.lidarAvailable ? "Available" : "Not Available")",
            "Report generated on \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short))"
        ]
        
        var yOffset = pageRect.height - 80
        for text in footer {
            let footerRect = CGRect(x: 50, y: yOffset, width: pageRect.width - 100, height: 20)
            text.draw(in: footerRect, withAttributes: footerAttributes)
            yOffset += 15
        }
    }
    
    private func generateFileName(for session: Session, extension fileExtension: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let dateString = dateFormatter.string(from: session.startedAt)
        
        // TODO: Get project and location names from DataStore
        let projectName = "Project" // Placeholder
        let locationName = "Location" // Placeholder
        
        return "\(dateString)_\(projectName)_\(locationName)_Session-\(session.id.uuidString.prefix(8)).\(fileExtension)"
    }
    
    private func getDocumentsDirectory() throws -> URL {
        return try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    }
}

// MARK: - Export Manager

class ExportManager: ObservableObject {
    @Published var isExporting = false
    @Published var exportProgress: Double = 0.0
    @Published var exportError: String?
    
    private let exportService: ExportServiceProtocol
    
    init(exportService: ExportServiceProtocol = ExportService()) {
        self.exportService = exportService
    }
    
    func exportSession(_ session: Session, gridPoints: [GridPoint], photos: [PhotoAsset], format: ExportFormat) async throws -> URL {
        await MainActor.run {
            isExporting = true
            exportProgress = 0.0
            exportError = nil
        }
        
        defer {
            Task { @MainActor in
                isExporting = false
                exportProgress = 0.0
            }
        }
        
        await MainActor.run {
            exportProgress = 0.3
        }
        
        let fileURL: URL
        
        switch format {
        case .pdf:
            fileURL = try await exportService.generatePDF(for: session, gridPoints: gridPoints, photos: photos)
        case .csv:
            fileURL = try await exportService.generateCSV(for: session, gridPoints: gridPoints)
        case .json:
            fileURL = try await exportService.generateJSON(for: session, gridPoints: gridPoints, photos: photos)
        }
        
        await MainActor.run {
            exportProgress = 1.0
        }
        
        return fileURL
    }
}

// MARK: - Supporting Types

enum ExportFormat: String, CaseIterable {
    case pdf = "PDF"
    case csv = "CSV"
    case json = "JSON"
    
    var fileExtension: String {
        return rawValue.lowercased()
    }
    
    var mimeType: String {
        switch self {
        case .pdf:
            return "application/pdf"
        case .csv:
            return "text/csv"
        case .json:
            return "application/json"
        }
    }
}

// MARK: - Export View

struct ExportView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) private var dismiss
    
    let session: Session
    let gridPoints: [GridPoint]
    let photos: [PhotoAsset]
    
    @StateObject private var exportManager = ExportManager()
    @State private var selectedFormat: ExportFormat = .pdf
    @State private var exportedFileURL: URL?
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Format selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Export Format")
                        .font(.headline)
                    
                    Picker("Format", selection: $selectedFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // Export options
                VStack(alignment: .leading, spacing: 12) {
                    Text("Export Options")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Session data and measurements")
                        }
                        
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Statistical analysis")
                        }
                        
                        if selectedFormat == .pdf {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Photo thumbnails")
                            }
                        }
                        
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Tolerance analysis")
                        }
                    }
                }
                
                // Progress indicator
                if exportManager.isExporting {
                    VStack(spacing: 12) {
                        ProgressView(value: exportManager.exportProgress)
                            .progressViewStyle(LinearProgressViewStyle())
                        
                        Text("Exporting \(selectedFormat.rawValue)...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Export button
                Button(action: exportSession) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export \(selectedFormat.rawValue)")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
                }
                .disabled(exportManager.isExporting)
            }
            .padding()
            .navigationTitle("Export Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = exportedFileURL {
                ShareSheet(activityItems: [url])
            }
        }
        .alert("Export Error", isPresented: .constant(exportManager.exportError != nil)) {
            Button("OK") {
                exportManager.exportError = nil
            }
        } message: {
            Text(exportManager.exportError ?? "")
        }
    }
    
    private func exportSession() {
        Task {
            do {
                let fileURL = try await exportManager.exportSession(session, gridPoints: gridPoints, photos: photos, format: selectedFormat)
                
                await MainActor.run {
                    exportedFileURL = fileURL
                    showingShareSheet = true
                }
            } catch {
                await MainActor.run {
                    exportManager.exportError = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}

#Preview {
    ExportView(
        session: Session(
            locationId: UUID(),
            units: .imperial,
            tolerance: 0.5,
            rows: 4,
            cols: 4
        ),
        gridPoints: [],
        photos: []
    )
    .environmentObject(DataStore())
}
