//
//  QuickTableView.swift
//
//  Created by Daniel Loewenherz on 3/26/16.
//  Copyright © 2016 Lionheart Software LLC. All rights reserved.
//

import UIKit
import KeyboardAdjuster
import LionheartTableViewCells

public protocol QuickTableViewRowLike {
    var title: String? { get }
    var detail: String? { get }
    var type: UITableViewCellIdentifiable.Type { get }
}

public protocol QuickTableViewRowLikeExtended: QuickTableViewRowLike {
    associatedtype C
    func prepareCell(cell: C) -> C
    func dequeueReusableCellWithIdentifier(tableView: UITableView, forIndexPath indexPath: NSIndexPath) -> C
}

public enum QuickTableViewRow: QuickTableViewRowLikeExtended {
    public typealias C = UITableViewCell
    public typealias QuickTableViewHandler = UIViewController -> Void

    case Default(String?)
    case Subtitle(String?, String?)
    case Value1(String?, String?)
    case Value2(String?, String?)
    case Custom(UITableViewCellIdentifiable.Type, (C) -> C)

    indirect case RowWithSetup(QuickTableViewRow, (C) -> C)
    indirect case RowWithHandler(QuickTableViewRow, QuickTableViewHandler)

    public func onSelection(handler: QuickTableViewHandler) -> QuickTableViewRow {
        if case .RowWithHandler(let row, _) = self {
            return .RowWithHandler(row, handler)
        }
        else {
            return .RowWithHandler(self, handler)
        }
    }

    public func dequeueReusableCellWithIdentifier(tableView: UITableView, forIndexPath indexPath: NSIndexPath) -> C {
        return prepareCell(tableView.dequeueReusableCellWithIdentifier(type.identifier, forIndexPath: indexPath))
    }

    public func prepareCell(cell: C) -> C {
        cell.textLabel?.text = self.title
        cell.detailTextLabel?.text = self.detail

        if case .Custom(_, let callback) = self {
            return callback(cell)
        }
        else if case .RowWithSetup(let row, let callback) = self {
            return row.prepareCell(callback(cell))
        }
        else if case .RowWithHandler(let row, _) = self {
            return row.prepareCell(cell)
        }
        return cell
    }

    public var title: String? {
        switch self {
        case .Default(let title):
            return title

        case .Subtitle(let title, _):
            return title

        case .Value1(let title, _):
            return title

        case .Value2(let title, _):
            return title

        case .Custom:
            return nil

        case .RowWithHandler(let row, _):
            return row.title

        case .RowWithSetup(let row, _):
            return row.title
        }
    }

    public var detail: String? {
        switch self {
        case .Default:
            return nil

        case .Subtitle(_, let detail):
            return detail

        case .Value1(_, let detail):
            return detail

        case .Value2(_, let detail):
            return detail

        case .Custom:
            return nil

        case .RowWithHandler(let row, _):
            return row.detail

        case .RowWithSetup(let row, _):
            return row.detail
        }
    }

    public var type: UITableViewCellIdentifiable.Type {
        switch self {
        case .Default:
            return TableViewCellDefault.self

        case .Subtitle:
            return TableViewCellSubtitle.self

        case .Value1:
            return TableViewCellValue1.self

        case .Value2:
            return TableViewCellValue2.self

        case .Custom(let type, _):
            return type

        case .RowWithHandler(let row, _):
            return row.type

        case .RowWithSetup(let row, _):
            return row.type
        }
    }
}

public enum QuickTableViewSection: ArrayLiteralConvertible {
    public typealias Row = QuickTableViewRow
    public typealias Element = Row
    var count: Int { return rows.count }

    case Default([Row])
    case Title(String, [Row])

    public init(name theName: String, rows theRows: [Row]) {
        self = .Title(theName, theRows)
    }

    public init(_ rows: [Row]) {
        self = .Default(rows)
    }

    public init(arrayLiteral elements: Element...) {
        self = .Default(elements)
    }

    subscript(index: Int) -> Row {
        return rows[index]
    }

    var name: String? {
        if case .Title(let title, _) = self {
            return title
        }
        else {
            return nil
        }
    }

    var rows: [QuickTableViewRow] {
        switch self {
        case .Default(let rows):
            return rows

        case .Title(_, let rows):
            return rows
        }
    }

    var TableViewCellClasses: [UITableViewCellIdentifiable.Type] {
        return rows.map { $0.type }
    }
}

public protocol QuickTableViewContainer {
    static var sections: [QuickTableViewSection] { get }
    static var style: UITableViewStyle { get }
    static var shouldAutoResizeCells: Bool { get }
}

public class BaseTableViewController: UIViewController, KeyboardAdjuster {
    public var keyboardAdjusterConstraint: NSLayoutConstraint?
    public var keyboardAdjusterAnimated: Bool? = false
    public var tableView: UITableView!

    public init(style: UITableViewStyle = .Grouped) {
        super.init(nibName: nil, bundle: nil)

        tableView = UITableView(frame: CGRect.zero, style: style)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self as? UITableViewDelegate
        tableView.dataSource = self as? UITableViewDataSource
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        activateKeyboardAdjuster()
    }

    override public func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        deactivateKeyboardAdjuster()
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(tableView)

        tableView.leftAnchor.constraintEqualToAnchor(view.leftAnchor).active = true
        tableView.rightAnchor.constraintEqualToAnchor(view.rightAnchor).active = true
        tableView.topAnchor.constraintEqualToAnchor(view.topAnchor).active = true
        keyboardAdjusterConstraint = view.bottomAnchor.constraintEqualToAnchor(tableView.bottomAnchor)
    }

    // MARK: -
    public func leftBarButtonItemDidTouchUpInside(sender: AnyObject?) {
        parentViewController?.dismissViewControllerAnimated(true, completion: nil)
    }

    public func rightBarButtonItemDidTouchUpInside(sender: AnyObject?) {
        parentViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
}

public class QuickTableViewController<Container: QuickTableViewContainer>: BaseTableViewController, UITableViewDataSource, UITableViewDelegate {
    required public init() {
        super.init(style: Container.style)

        if Container.shouldAutoResizeCells {
            tableView.estimatedRowHeight = 44
            tableView.rowHeight = UITableViewAutomaticDimension
        }
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        var registeredClassIdentifiers: Set<String> = Set()
        for section in Container.sections {
            for type in section.TableViewCellClasses {
                if !registeredClassIdentifiers.contains(type.identifier) {
                    tableView.registerClass(type)
                    registeredClassIdentifiers.insert(type.identifier)
                }
            }
        }
    }

    public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return Container.sections.count
    }

    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Container.sections[section].count
    }

    public func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Container.sections[section].name
    }

    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let section = Container.sections[indexPath.section]
        let row = section.rows[indexPath.row]
        switch row {
        case .Custom(let CellType, let callback):
            let cell = tableView.dequeueReusableCellWithIdentifier(CellType.identifier, forIndexPath: indexPath)
            return row.prepareCell(cell)

        default:
            let cell = tableView.dequeueReusableCellWithIdentifier(row.type.identifier, forIndexPath: indexPath)
            return row.prepareCell(cell)
        }
    }

    public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)

        let section = Container.sections[indexPath.section]
        if case .RowWithHandler(_, let handler) = section[indexPath.row] {
            handler(self)
        }
    }
}