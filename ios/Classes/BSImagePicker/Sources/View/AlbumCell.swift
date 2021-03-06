// The MIT License (MIT)
//
// Copyright (c) 2015 Joakim Gyllström
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import UIKit

/**
Cell for photo albums in the albums drop down menu
*/
final class AlbumCell: UITableViewCell {
    static let cellIdentifier = "albumCell"

    let firstImageView: UIImageView = UIImageView(frame: .zero)
    let secondImageView: UIImageView = UIImageView(frame: .zero)
    let thirdImageView: UIImageView = UIImageView(frame: .zero)
    let albumTitleLabel: UILabel = UILabel(frame: .zero)

    private let imageContainerView: UIView = UIView(frame: .zero)

    override var isSelected: Bool {
        didSet {
            // Selection checkmark
            if isSelected == true {
                accessoryType = .checkmark
            } else {
                accessoryType = .none
            }
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.backgroundColor = UIColor.clear
        backgroundColor = UIColor.clear
        selectionStyle = .none

        imageContainerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageContainerView)
        albumTitleLabel.numberOfLines = 3
        albumTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(albumTitleLabel)
        
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: imageContainerView, attribute: .top, relatedBy: .equal, toItem: contentView, attribute: .top, multiplier: 1, constant: 8),
            NSLayoutConstraint(item: imageContainerView, attribute: .bottom, relatedBy: .equal, toItem: contentView, attribute: .bottom, multiplier: 1, constant: -8),
            NSLayoutConstraint(item: imageContainerView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 84),
            NSLayoutConstraint(item: imageContainerView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: 84),
            NSLayoutConstraint(item: imageContainerView, attribute: .leading, relatedBy: .equal, toItem: contentView, attribute: .leading, multiplier: 1, constant: 8),
            
            NSLayoutConstraint(item: albumTitleLabel, attribute: .leading, relatedBy: .equal, toItem: imageContainerView, attribute: .trailing, multiplier: 1, constant: 8),
            NSLayoutConstraint(item: albumTitleLabel, attribute: .trailing, relatedBy: .equal, toItem: contentView, attribute: .trailing, multiplier: 1, constant: -8),
            NSLayoutConstraint(item: albumTitleLabel, attribute: .top, relatedBy: .equal, toItem: contentView, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: albumTitleLabel, attribute: .bottom, relatedBy: .equal, toItem: contentView, attribute: .bottom, multiplier: 1, constant: 0),
        ])

        [thirdImageView, secondImageView, firstImageView].forEach {
            imageContainerView.addSubview($0)
            NSLayoutConstraint.activate([
                NSLayoutConstraint(item: $0, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 79),
                NSLayoutConstraint(item: $0, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: 79)
            ])

            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.layer.shadowColor = UIColor.white.cgColor
            $0.layer.shadowRadius = 1.0
            $0.layer.shadowOffset = CGSize(width: 0.5, height: -0.5)
            $0.layer.shadowOpacity = 1.0
            $0.clipsToBounds = true
            $0.contentMode = .scaleAspectFill
        }

        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: thirdImageView, attribute: .leading, relatedBy: .equal, toItem: imageContainerView, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: thirdImageView, attribute: .top, relatedBy: .equal, toItem: imageContainerView, attribute: .top, multiplier: 1, constant: 0),
            
            NSLayoutConstraint(item: secondImageView, attribute: .centerX, relatedBy: .equal, toItem: imageContainerView, attribute: .centerX, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: secondImageView, attribute: .centerY, relatedBy: .equal, toItem: imageContainerView, attribute: .centerY, multiplier: 1, constant: 0),
            
            NSLayoutConstraint(item: firstImageView, attribute: .trailing, relatedBy: .equal, toItem: imageContainerView, attribute: .trailing, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: firstImageView, attribute: .bottom, relatedBy: .equal, toItem: imageContainerView, attribute: .bottom, multiplier: 1, constant: 0)
        ])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        firstImageView.image = nil
        secondImageView.image = nil
        thirdImageView.image = nil
        albumTitleLabel.text = nil
    }
}
