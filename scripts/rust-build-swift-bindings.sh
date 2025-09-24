echo ">>"; echo ">> Cleanup"; echo ">>"
cargo clean
echo ">>"; echo ">> Build release"; echo ">>"
cargo build --release

# Check for arguments
if [ $# -eq 0 ]; then
    echo "No arguments provided."
    echo "   First  argument has to be a (semantic) version, e.g. '1.2.3'"
    echo "   Second argument has to be a Swift package name, e.g. 'DidResolver'"
    echo "   Third  argument has to be a XCFramework name,   e.g. 'didresolver'"
    echo "   Fourth argument has to be a GitHub owner of the repo hosting the Swift release package, e.g. 'swiyu-admin-ch'"
    echo "   Fifth  argument has to be a GitHub repo hosting the Swift release package, e.g. 'didresolver-swift'"
    exit 1
fi

version=$1
swift_package_name=$2
xcframework_name=$3
binary_target_url_github_owner=$4
binary_target_url_github_repo=$5

echo ">>"; echo ">> Generating UniFFI bindings for Swift package '${swift_package_name}' ver. ${version} ..."; echo ">>"
cargo run --bin uniffi-bindgen generate \
          --library target/release/lib${xcframework_name}.dylib \
          --language swift \
          --out-dir bindings/swift/files

# Only Tier: 2 (without Host Tools) targets (according to https://doc.rust-lang.org/rustc/platform-support/apple-ios.html)
# Control the minimum iOS version of your Rust library via the IPHONEOS_DEPLOYMENT_TARGET environment variable.
# Rust uses these values to determine the OS version passed to the linker via the -target flag.
# See https://doc.rust-lang.org/stable/rustc/platform-support/apple-ios.html?highlight=IPHONEOS_DEPLOYMENT_TARGET#os-version
echo ">>"; echo ">> Building for Apple iOS on ARM64..."; echo ">>"
IPHONEOS_DEPLOYMENT_TARGET=15.0 cargo build --release --target aarch64-apple-ios
echo ">>"; echo ">> Building for Apple iOS Simulator on ARM64..."; echo ">>"
IPHONEOS_DEPLOYMENT_TARGET=15.0 cargo build --release --target aarch64-apple-ios-sim
echo ">>"; echo ">> Building for Apple iOS Simulator on 64-bit x86..."; echo ">>"
IPHONEOS_DEPLOYMENT_TARGET=15.0 cargo build --release --target x86_64-apple-ios
ls -lh target/**/release/lib${xcframework_name}.a

# CAUTION In case of iOS Simulator, all the simulator-relevant libs must be combined into one single "fat" static library
echo ">>"; echo ">> Building a single 'fat' static library 'lib${xcframework_name}'..."; echo ">>"
lipo -create -output target/lib${xcframework_name}.a \
  target/aarch64-apple-ios-sim/release/lib${xcframework_name}.a \
  target/x86_64-apple-ios/release/lib${xcframework_name}.a
ls -lh target/lib${xcframework_name}.a

echo ">>"; echo ">> Merging all module maps together..."; echo ">>"
cat bindings/swift/files/*.modulemap > bindings/swift/files/module.modulemap

echo ">>"; echo ">> Building the XFC framework '${xcframework_name}'..."; echo ">>"
rm -r bindings/swift/${xcframework_name}.xcframework &>/dev/null
xcodebuild -create-xcframework \
  -library ./target/lib${xcframework_name}.a \
  -headers ./bindings/swift/files \
  -library ./target/aarch64-apple-ios/release/lib${xcframework_name}.a \
  -headers ./bindings/swift/files \
  -output "./bindings/swift/${xcframework_name}.xcframework"

rm bindings/swift/files/module.modulemap

# Preventing multiple modulemap build error (inspired by https://github.com/jessegrosjean/module-map-error and https://github.com/jessegrosjean/swift-cargo-problem)
echo ">>"; echo ">> Preventing 'multiple modulemap build error'..."; echo ">>"
cd bindings/swift/${xcframework_name}.xcframework
mkdir ios-arm64/Headers/${xcframework_name} \
      ios-arm64_x86_64-simulator/Headers/${xcframework_name}
mv ios-arm64/Headers/*.*                  ios-arm64/Headers/${xcframework_name}/
mv ios-arm64_x86_64-simulator/Headers/*.* ios-arm64_x86_64-simulator/Headers/${xcframework_name}/
# ZIP the XCFramework directory to create an release asset
cd ..
zip_file_name=${xcframework_name}-${version}.xcframework.zip
zip -r ${zip_file_name} ${xcframework_name}.xcframework
ls -lh ${zip_file_name}
# The checksum of the ZIP archive that contains the XCFramework, as required for any 'binaryTarget'
# See https://developer.apple.com/documentation/xcode/distributing-binary-frameworks-as-swift-packages
checksum=$(swift package compute-checksum ${zip_file_name})
echo ">>"; echo ">> Checksum of the ZIP archive containing the XCFramework: ${checksum}"; echo ">>"
cd ../..

echo ">>"; echo ">> Generating the Swift package structure..."; echo ">>"
mkdir -p output/Sources/${swift_package_name}
cp -r bindings/swift/${zip_file_name} output/
cp -r bindings/swift/${xcframework_name}.xcframework/ios-arm64/Headers/${xcframework_name}/*.swift output/Sources/${swift_package_name}

cat <<-EOF > output/Package.swift
// swift-tools-version:5.3
import PackageDescription

let version = "${version}"
let xcframework_name = "${xcframework_name}"
let binary_target_url_github_owner = "${binary_target_url_github_owner}"
let binary_target_url_github_repo = "${binary_target_url_github_repo}"
let checksum = "${checksum}"

let package = Package(
    name: "${swift_package_name}",
    platforms: [.iOS(.v14)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "${swift_package_name}",
            targets: ["${swift_package_name}", "${swift_package_name}RemoteBinaryPackage"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "${swift_package_name}"
        ),
        .binaryTarget(
            name: "${swift_package_name}RemoteBinaryPackage",
            url: "https://github.com/\(binary_target_url_github_owner)/\(binary_target_url_github_repo)/releases/download/\(version)/\(xcframework_name)-\(version).xcframework.zip",
            checksum: "\(checksum)"
        )
    ]
)
EOF
