//
//  BarItemCell.swift
//  CustomVerticalBar
//
//  Created by pradeepMac on 24/09/26.
//

import UIKit

struct BarItem {
    let title: String
    let iconName: String
}

final class BarItemCell: UICollectionViewCell {
    static let reuseIdentifier = "BarItemCell"

    var isItemSelected = false {
        didSet {
            updateSelectionAppearance()
        }
    }

    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .label
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11, weight: .regular)
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        contentView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            iconImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            iconImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 28),
            iconImageView.heightAnchor.constraint(equalToConstant: 28),

            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 4),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 2),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -2),
            titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -4)
        ])

        contentView.layer.cornerRadius = 12
        contentView.layer.masksToBounds = true
        updateSelectionAppearance()
    }

    func configure(with item: BarItem) {
        titleLabel.text = item.title
        iconImageView.image = UIImage(systemName: item.iconName)
        accessibilityLabel = item.title
    }

    private func updateSelectionAppearance() {
        contentView.backgroundColor = isItemSelected
            ? tintColor.withAlphaComponent(0.18)
            : .clear
        iconImageView.tintColor = isItemSelected ? tintColor : .label
        titleLabel.textColor = isItemSelected ? tintColor : .label
        accessibilityTraits = isItemSelected ? [.button, .selected] : [.button]
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        iconImageView.image = nil
        accessibilityLabel = nil
        isItemSelected = false
    }
}
