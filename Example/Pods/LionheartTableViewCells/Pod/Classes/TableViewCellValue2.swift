//
//  TableViewCellValue2.swift
//  Pods
//
//  Created by Daniel Loewenherz on 2/10/16.
//
//

public class TableViewCellValue2: UITableViewCell, LionheartTableViewCell {
    public static var identifier: String = "Value1CellIdentifier"

    public override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .Value2, reuseIdentifier: reuseIdentifier)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
