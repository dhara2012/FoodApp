import SwiftUI

struct AvatarView: View {
    let photo: UIImage?
    let initials: String
    var size: CGFloat = 40

    var body: some View {
        Group {
            if let photo {
                Image(uiImage: photo).resizable().scaledToFill()
            } else {
                ZStack {
                    LinearGradient(colors: [.orange, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                    Text(initials).font(.system(size: size * 0.4, weight: .bold)).foregroundColor(.white)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}
